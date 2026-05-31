# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 RVLab Contributors

from pydesignflow import Block, task
from .tools import verilator
import os


class Ddr3BoundaryTb(Block):
    """Focused DDR3 controller/PHY/model boundary testbench."""

    name = "ddr3_boundary_tb"

    @task(requires={
        "srcs": "srcs.srcs_ddr3_boundary_verilator",
    })
    def sim_rtl_verilator(self, cwd, srcs):
        plusargs = {}
        timeout_ps = os.environ.get("RVLAB_DDR3_BOUNDARY_TIMEOUT_PS")
        if timeout_ps:
            plusargs["ddr_boundary_timeout_ps"] = timeout_ps

        verilator.simulate(
            srcs.design_srcs + srcs.tb_srcs,
            [self.name],
            cwd=cwd,
            include_dirs=srcs.include_dirs,
            defines=srcs.defines,
            plusargs=plusargs,
            unisims_dir=srcs.unisims_dir,
            trace=False,
        )
