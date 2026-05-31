# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 RVLab Contributors

from pydesignflow import Block, task, Result
from .tools.vivado import vivado_dir
from pathlib import Path
import shutil
import re
import os

MICRON_MODEL_FILES = [
    "ddr3.v",
    "1024Mb_ddr3_parameters.vh",
    "2048Mb_ddr3_parameters.vh",
    "4096Mb_ddr3_parameters.vh",
    "8192Mb_ddr3_parameters.vh",
]

PHY_MODEL_FILES = [
    "IDELAYCTRL_model.v",
    "IDELAYE2_model.v",
    "IOBUF_DCIEN_model.v",
    "IOBUF_model.v",
    "IOBUFDS_DCIEN_model.v",
    "IOBUFDS_model.v",
    "ISERDESE2_model.v",
    "OBUF_model.v",
    "OBUFDS_model.v",
    "ODELAYE2_model.v",
    "OSERDESE2_model.v",
]

def replace_in_file(filepath: Path, x: dict[str,str]):
    pattern = re.compile('|'.join(re.escape(k) for k in sorted(x, key=len, reverse=True)))
    content = filepath.read_text()
    filepath.write_text(pattern.sub(lambda m: x[m.group(0)], content))

class Ddr3Model(Block):
    """Obtain simulation model of DDR3 chip."""

    def _copy_micron_model(self, src_dir: Path, cwd: Path):
        missing = [name for name in MICRON_MODEL_FILES if not (src_dir / name).exists()]
        if missing:
            raise FileNotFoundError(
                f"DDR3 model directory {src_dir} is missing required files: {', '.join(missing)}"
            )

        for name in MICRON_MODEL_FILES:
            shutil.copy(src_dir / name, cwd / name)

        tb_srcs = [cwd / "ddr3.v"]
        phy_model_dir = os.environ.get("RVLAB_DDR3_PHY_MODEL_DIR")
        if phy_model_dir:
            phy_model_src_dir = Path(phy_model_dir)
            missing = [name for name in PHY_MODEL_FILES if not (phy_model_src_dir / name).exists()]
            if missing:
                raise FileNotFoundError(
                    f"DDR3 PHY model directory {phy_model_src_dir} is missing required files: "
                    f"{', '.join(missing)}"
                )
            for name in PHY_MODEL_FILES:
                shutil.copy(phy_model_src_dir / name, cwd / name)
                tb_srcs.append(cwd / name)

        r = Result()
        r.tb_srcs = tb_srcs
        r.include_dirs = [cwd]
        r.defines = {
            "den4096Mb": "1",
            "x16": "1",
            "sg187E": "1",
            "MAX_MEM": "1",
        }
        if phy_model_dir:
            r.defines["SIM_MODEL"] = "1"
            r.defines["NO_TEST_MODEL"] = "1"
        return r

    def _copy_vivado_model(self, cwd: Path):
        ddr3_sim_dir = vivado_dir() / 'data/ip/xilinx/mig_7series_v4_2/data/dlib/7series/ddr3_sdram/sim'

        shutil.copy(ddr3_sim_dir / "ddr3_model.sv", cwd / "ddr3.sv")
        shutil.copy(ddr3_sim_dir / "ddr3_model_parameters.vh", cwd / "ddr3_parameters.vh")

        replace_in_file(cwd / 'ddr3.sv', {
                "%cntInfo_lddr3_model": "ddr3",
                "%MEM_DENSITY": "4Gb",
                "%MEM_SPEEDGRADE": "187E",
                "%MEM_DEVICE_WIDTH": "16",
            })

        r = Result()
        r.tb_srcs = [cwd / 'ddr3.sv']
        r.include_dirs = [cwd]

        return r

    @task()
    def generate(self, cwd):
        """Generate proprietary Vivado DDR3 simulation model sources"""

        return self._copy_vivado_model(cwd)

    @task()
    def generate_verilator(self, cwd):
        """Generate DDR3 simulation model sources for Verilator"""

        ddr3_model_dir = os.environ.get("RVLAB_DDR3_MODEL_DIR")
        if ddr3_model_dir:
            return self._copy_micron_model(Path(ddr3_model_dir), cwd)

        return self._copy_vivado_model(cwd)
