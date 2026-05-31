# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 RVLab Contributors

import os
import re
import shlex
import shutil
import subprocess
from pathlib import Path


def _repo_default(base_dir: Path, relpath: str) -> Path:
    return base_dir / relpath


def _tool(name: str) -> str:
    path = shutil.which(name)
    if path is None:
        raise FileNotFoundError(f"Required openXC7 tool not found in PATH: {name}")
    return path


def _run(cmd: list[str], cwd: Path, logfile: Path, env: dict[str, str] | None = None) -> None:
    print(shlex.join(cmd))
    with logfile.open("w") as f:
        subprocess.check_call(cmd, cwd=cwd, stdout=f, stderr=subprocess.STDOUT, env=env)


def chipdb_path(base_dir: Path, part: str) -> Path:
    default = _repo_default(base_dir, f".deps/openxc7/source-chipdb/{part}.bin")
    return Path(os.environ.get("OPENXC7_CHIPDB", default))


def prjxray_db_root(base_dir: Path) -> Path:
    default = _repo_default(base_dir, ".deps/openxc7/source-prefix/share/nextpnr/prjxray-db/artix7")
    return Path(os.environ.get("PRJXRAY_DB_ROOT", default))


def part_yaml(base_dir: Path, part: str) -> Path:
    default = prjxray_db_root(base_dir) / part / "part.yaml"
    return Path(os.environ.get("OPENXC7_PART_YAML", default))


def _yosys_read_args(srcs, include_dirs, defines) -> list[str]:
    args = []
    for path in include_dirs:
        args += ["-I" + str(path)]
    for key, value in defines.items():
        args += ["-D" + f"{key}={value}"]
    args += [str(src) for src in srcs]
    return args


def _nextpnr_xdc(src: Path, dst: Path) -> Path:
    set_property_dict = re.compile(r"^(\s*)set_property\s+-dict\s+\{([^}]*)\}\s+(.+?)(\s*(?:#.*)?)$")
    set_property_simple = re.compile(r"^(\s*)set_property\s+(\S+)\s+(\S+)\s+(\[get_ports .+\])(\s*(?:#.*)?)$")
    get_ports_braced = re.compile(r"\[get_ports\s+\{\s*([^}]+?)\s*\}\]")

    def normalize_target(target: str) -> str:
        target = target.rstrip(";")
        return get_ports_braced.sub(lambda m: f"[get_ports {m.group(1).strip()}]", target)

    def target_aliases(target: str) -> list[str]:
        match = re.fullmatch(r"\[get_ports ([^\[\]\s]+)\[0\]\]", target)
        if match:
            return [target, f"[get_ports {match.group(1)}]"]
        return [target]

    with src.open() as f_in, dst.open("w") as f_out:
        for line in f_in:
            stripped = line.lstrip()
            match = set_property_dict.match(line.rstrip("\n"))
            if not match:
                if stripped.startswith("set_property") and "[get_ports" not in line:
                    f_out.write("# openXC7 unsupported: " + line)
                    continue
                normalized = get_ports_braced.sub(
                    lambda m: f"[get_ports {m.group(1).strip()}]",
                    line.rstrip("\n").rstrip(";"))
                simple = set_property_simple.match(normalized)
                if simple:
                    indent, prop, value, target, comment = simple.groups()
                    for alias_idx, alias in enumerate(target_aliases(target)):
                        suffix = comment if alias_idx == 0 else ""
                        f_out.write(f"{indent}set_property {prop} {value} {alias}{suffix}\n")
                else:
                    f_out.write(normalized + "\n")
                continue

            indent, dict_body, target, comment = match.groups()
            tokens = shlex.split(dict_body)
            if len(tokens) % 2 != 0:
                raise ValueError(f"Malformed XDC set_property -dict line in {src}: {line.rstrip()}")

            target = normalize_target(target)
            if "[get_ports" not in target:
                f_out.write("# openXC7 unsupported: " + line)
                continue
            for alias_idx, alias in enumerate(target_aliases(target)):
                for idx in range(0, len(tokens), 2):
                    suffix = comment if alias_idx == 0 and idx == 0 else ""
                    f_out.write(f"{indent}set_property {tokens[idx]} {tokens[idx + 1]} {alias}{suffix}\n")

    return dst


def synth_xilinx(cwd: Path, base_dir: Path, srcs, top: str, json_out: Path, edif_out: Path | None = None) -> None:
    _tool("yosys")

    script = [
        "plugin -i slang",
        "read_verilog -lib +/xilinx/cells_sim.v +/xilinx/cells_xtra.v",
        f"read_slang --single-unit --ignore-unknown-modules --top {top} " + shlex.join(_yosys_read_args(
            srcs.design_srcs, srcs.include_dirs, srcs.defines
        )),
        f"hierarchy -top {top}",
        "flatten",
        f"synth_xilinx -family xc7 -top {top}",
        "delete t:$print",
        "stat",
        f"write_json {json_out}",
    ]
    if edif_out is not None:
        script.append(f"write_edif {edif_out}")

    _run(["yosys", "-p", "; ".join(script)], cwd=cwd, logfile=cwd / "yosys.log")


def place_and_route(
    cwd: Path,
    base_dir: Path,
    part: str,
    json_in: Path,
    xdc_files,
    json_out: Path,
    fasm_out: Path,
    freq_mhz: int,
) -> None:
    _tool("nextpnr-xilinx")
    chipdb = chipdb_path(base_dir, part)
    if not chipdb.exists():
        raise FileNotFoundError(f"openXC7 chipdb not found: {chipdb}")

    nextpnr_xdc_files = [
        _nextpnr_xdc(Path(xdc), cwd / f"{Path(xdc).stem}.openxc7.xdc")
        for xdc in xdc_files
    ]

    cmd = [
        "nextpnr-xilinx",
        "--chipdb", str(chipdb),
        "--json", str(json_in),
        "--write", str(json_out),
        "--fasm", str(fasm_out),
        "--freq", str(freq_mhz),
    ]
    for xdc in nextpnr_xdc_files:
        cmd += ["--xdc", str(xdc)]

    _run(cmd, cwd=cwd, logfile=cwd / "nextpnr.log")


def bitstream(cwd: Path, base_dir: Path, part: str, fasm_in: Path, frames_out: Path, bit_out: Path) -> None:
    _tool("fasm2frames")
    _tool("xc7frames2bit")

    db_root = prjxray_db_root(base_dir)
    yaml = part_yaml(base_dir, part)
    if not db_root.exists():
        raise FileNotFoundError(f"Project X-Ray DB root not found: {db_root}")
    if not yaml.exists():
        raise FileNotFoundError(f"Project X-Ray part yaml not found: {yaml}")

    env = os.environ.copy()
    openxc7_python = base_dir / ".deps/openxc7/source-prefix/lib/python"
    env["PYTHONPATH"] = str(openxc7_python) + os.pathsep + env.get("PYTHONPATH", "")

    _run([
        "fasm2frames",
        "--db-root", str(db_root),
        "--part", part,
        str(fasm_in),
        str(frames_out),
    ], cwd=cwd, logfile=cwd / "fasm2frames.log", env=env)

    _run([
        "xc7frames2bit",
        "--part_file", str(yaml),
        "--part_name", part,
        "--frm_file", str(frames_out),
        "--output_file", str(bit_out),
    ], cwd=cwd, logfile=cwd / "xc7frames2bit.log")
