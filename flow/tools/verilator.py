# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 RVLab Contributors

import subprocess
from pathlib import Path
from typing import Optional, List, Dict
import os
import sys

def find_verilator_executable() -> List[str]:
    """Find Verilator executable, handling Windows/MSYS2 environment"""
    if sys.platform == "win32":
        # Windows/MSYS2: verilator is a Perl script
        # Try to find perl and verilator script
        perl_exe = None
        verilator_script = None
        
        # Look for MSYS2 perl
        mingw_prefix = os.getenv('MINGW_PREFIX')
        if mingw_prefix:
            # Typical MSYS2 path: /mingw64/bin/perl.exe or /usr/bin/perl.exe
            potential_perl = Path(mingw_prefix) / "bin" / "perl.exe"
            if potential_perl.exists():
                perl_exe = str(potential_perl)
            else:
                # Try parent/usr/bin
                potential_perl = Path(mingw_prefix).parent / "usr" / "bin" / "perl.exe"
                if potential_perl.exists():
                    perl_exe = str(potential_perl)
        
        # Look for verilator script
        if mingw_prefix:
            potential_verilator = Path(mingw_prefix) / "bin" / "verilator"
            if potential_verilator.exists():
                verilator_script = str(potential_verilator)
        
        if perl_exe and verilator_script:
            return [perl_exe, verilator_script]
        else:
            # Fallback to just "verilator" and hope it's in PATH
            print("Warning: Could not find MSYS2 Perl or Verilator script, using 'verilator' from PATH")
            return ["verilator"]
    else:
        # Unix-like systems
        return ["verilator"]

def compile(
        src_files: List[Path],
        cwd: Optional[Path] = None,
        include_dirs: List[Path] = [],
        defines: Dict[str, str] = {},
        timescale: str = "1ps/1fs",
        top_modules: List[str] = ["top"],
        unisims_dir: Optional[Path] = None):
    """Compile Verilog sources with Verilator"""
    if cwd is None:
        cwd = Path.cwd()
    if unisims_dir is None:
        raise ValueError("unisims_dir must be provided for Verilator simulation")

    top_module = top_modules[0]  # Assuming the first top module is the primary one

    # Deduplicate source files while preserving order
    seen = set()
    unique_src_files = []
    for src in src_files:
        src_str = str(src)
        if src_str not in seen:
            seen.add(src_str)
            unique_src_files.append(src)
    if len(unique_src_files) != len(src_files):
        print(f"Warning: Removed {len(src_files) - len(unique_src_files)} duplicate source files")

    verilator_opts = [
        '-y', str(unisims_dir),
        '--Wno-fatal',
        '--Wno-EOFNEWLINE',
        '--bbox-unsup',  # Blackbox modules with unsupported constructs like 'deassign'
        '--timing',
        '--binary',
        '--trace',
        '--main',
        '--exe',
        '--cc',
        '--top-module', top_module,
        '--timescale', f"{timescale}",
    ]

    for key, value in defines.items():
        verilator_opts += [f"-D{key}={value}"]

    for include_dir in include_dirs:
        verilator_opts += [f"-I{include_dir}"]

    verilator_opts += [str(src) for src in unique_src_files]

    # Get verilator command
    verilator_cmd = find_verilator_executable()
    
    print(f"Running Verilator compile command:\n{' '.join(verilator_cmd)} {' '.join(verilator_opts)}")
    subprocess.check_call(verilator_cmd + verilator_opts, cwd=cwd)

    # Build the simulation
    executable_basename = f"V{top_module}"
    make_cmd = ["make", "-j", "-C", "obj_dir", "-f", f"{executable_basename}.mk", executable_basename]
    print(f"Building Verilator simulation:\n{' '.join(make_cmd)}")
    subprocess.check_call(make_cmd, cwd=cwd)

def simulate(
        src_files: List[Path],
        top_modules: List[str],
        unisims_dir: Path,
        cwd: Optional[Path] = None,
        include_dirs: List[Path] = [],
        defines: Dict[str, str] = {},
        wave_do: Optional[Path] = None,
        sdf: Dict[str, Path] = {},
        vcd_out: Optional[Path] = None,
        saif_out: Optional[Path] = None,
        log_all: bool = False,
        run_on_start: bool = True,
        batch_mode: bool = False,
        timescale: str = "1ps/1fs",
        plusargs: Dict[str, str] = {},
        netlist_sim = None,
        libs: List = [],
        hide_mig_timingcheck_msg: bool = False,
        ):
    """Run simulation with Verilator"""
    if cwd is None:
        cwd = Path.cwd()
    
    # Compile and build with Verilator
    compile(src_files, cwd, include_dirs, defines, timescale, top_modules, unisims_dir)

    top_module = top_modules[0]
    executable_basename = f"V{top_module}"
    executable_path = Path(cwd) / "obj_dir" / executable_basename

    if sys.platform == "win32":
        executable_path = executable_path.with_suffix(".exe")

    if not executable_path.exists():
        raise FileNotFoundError(f"Verilator simulation executable {executable_path} not found.")

    # Build command line with plusargs
    sim_cmd = [str(executable_path)]
    for key, value in plusargs.items():
        sim_cmd.append(f"+{key}={value}")

    # Add VCD dump if requested
    if vcd_out:
        sim_cmd.append("+vcd")

    print(f"Running Verilator simulation command:\n{' '.join(sim_cmd)}")
    try:
        result = subprocess.run(
            sim_cmd,
            cwd=cwd,
            text=True,
            check=True
        )
        print(f"Verilator simulation completed successfully (return code {result.returncode}).")
        if vcd_out:
            # The default trace file from Verilator's --main is trace.vcd in the CWD.
            default_vcd = cwd / "trace.vcd"
            if default_vcd.is_file():
                vcd_out.parent.mkdir(parents=True, exist_ok=True)
                default_vcd.rename(vcd_out)
                print(f"VCD trace file moved to {vcd_out}")
    except subprocess.CalledProcessError as e:
        print(f"ERROR: Verilator simulation failed with return code {e.returncode}.", file=sys.stderr)
        raise
    except FileNotFoundError:
        print(f"ERROR: Verilator simulation executable not found.", file=sys.stderr)
        raise