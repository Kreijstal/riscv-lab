# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 RVLab Contributors

from pydesignflow import Block, task, Result
from .tools import vivado
import subprocess
from .tools.overlay import filter_solutions_overlay
from pathlib import Path

def _apply_unisims_patches(unisims_repo: Path, patches_dir: Path) -> None:
    patch_files = sorted(patches_dir.glob("*.patch"))
    if not patch_files:
        return

    for patch_file in patch_files:
        reverse_check = subprocess.run(
            ["git", "-C", str(unisims_repo), "apply", "--reverse", "--check", str(patch_file)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if reverse_check.returncode == 0:
            continue

        forward_check = subprocess.run(
            ["git", "-C", str(unisims_repo), "apply", "--check", str(patch_file)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if forward_check.returncode != 0:
            raise RuntimeError(f"Failed to apply Unisims patch {patch_file}")

        subprocess.check_call(["git", "-C", str(unisims_repo), "apply", str(patch_file)])

class Sources(Block):
    """Hardware sources"""

    def setup(self):
        self.src_dir = self.flow.base_dir / "src"

    @task(requires={
        'xbar':'xbar.generate',
        'reggen':'reggen.generate',
        'swinit':'swinit.build',
        }, always_rebuild=True, hidden=True)
    def srcs_noddr(self, cwd, xbar, reggen, swinit):
        """RTL + verification sources without DDR3"""
        r = Result()

        design_srcs_pkg = []
        design_srcs_pkg += [self.src_dir / "rtl/inc/prim_assert.sv"]
        for d in ["rvlab_fpga", "prim", "prim2", "ibex", "tlul", "rv_dm"]:
            design_srcs_pkg += [x for x in self.src_dir.glob(f"rtl/{d}/pkg/*.sv")]
        design_srcs = []
        design_srcs += [x for x in self.src_dir.glob("rtl/*/*.sv")]    

        r.tb_srcs = [x for x in self.src_dir.glob("tb/*.sv")]
        r.tb_srcs += [vivado.vivado_dir() / "data/verilog/src/glbl.v"]
        r.tb_srcs = filter_solutions_overlay(r.tb_srcs, self.src_dir)


        r.design_srcs = design_srcs_pkg + xbar.rtl_srcs + reggen.rtl_srcs + design_srcs
        r.design_srcs = filter_solutions_overlay(r.design_srcs, self.src_dir)

        r.defines = {
            'INIT_MEM_FILE':swinit.mem,
        }
        
        r.include_dirs = [self.src_dir/"rtl/inc"]
        
        r.xcis = []
        
        return r

    @task(requires={
        'base_srcs':'.srcs_noddr',
        }, always_rebuild=True, hidden=True)
    def srcs_noddr_verilator(self, cwd, base_srcs):
        """RTL + verification sources without DDR3, with Verilator vendored dependencies"""
        r = Result()

        # Copy all attributes from base sources
        r.design_srcs = base_srcs.design_srcs
        r.defines = base_srcs.defines
        r.include_dirs = base_srcs.include_dirs
        r.xcis = base_srcs.xcis

        unisims_repo = self.flow.base_dir / "vendor" / "XilinxUnisimLibrary"
        patches_dir = self.flow.base_dir / "patches" / "unisims"
        _apply_unisims_patches(unisims_repo, patches_dir)

        # Use vendored glbl.v from XilinxUnisimLibrary submodule
        vendored_glbl = unisims_repo / "verilog" / "src" / "glbl.v"
        if not vendored_glbl.exists():
            raise FileNotFoundError(f"Vendored glbl.v not found at {vendored_glbl}")
        
        r.tb_srcs = [x for x in base_srcs.tb_srcs if not str(x).endswith('glbl.v')] + [vendored_glbl]
        
        # Add Verilator-specific vendored unisims directory
        r.unisims_dir = unisims_repo / "verilog" / "src" / "unisims"

        return r

    @task(requires={
        'base_srcs':'.srcs_noddr',
        }, always_rebuild=True, hidden=True)
    def srcs_module_verilator(self, cwd, base_srcs):
        """RTL + verification sources for module-level testbenches with Verilator"""
        r = Result()

        # Copy all attributes from base sources
        r.design_srcs = base_srcs.design_srcs
        r.defines = base_srcs.defines
        r.include_dirs = base_srcs.include_dirs
        r.xcis = base_srcs.xcis

        # Filter out FPGA-specific files that use Xilinx primitives
        # These files are not needed for module-level testbenches
        rvlab_fpga_dir = self.src_dir / "rtl" / "rvlab_fpga"
        filtered_design_srcs = []
        for src in r.design_srcs:
            # Keep package files (they don't instantiate primitives)
            if src.parent.name == 'pkg':
                filtered_design_srcs.append(src)
                continue
            # Skip other files from rvlab_fpga directory
            if rvlab_fpga_dir in src.parents:
                continue
            filtered_design_srcs.append(src)
        r.design_srcs = filtered_design_srcs

        # For Verilator module testbenches, we don't need glbl.v
        # Filter out any glbl.v files from base sources
        r.tb_srcs = [x for x in base_srcs.tb_srcs if not str(x).endswith('glbl.v')]
        
        # Add Verilator-specific vendored unisims directory
        unisims_repo = self.flow.base_dir / "vendor" / "XilinxUnisimLibrary"
        patches_dir = self.flow.base_dir / "patches" / "unisims"
        _apply_unisims_patches(unisims_repo, patches_dir)
        r.unisims_dir = unisims_repo / "verilog" / "src" / "unisims"

        return r

    @task(requires={
        'noddr':'.srcs_noddr',
        'mig':'mig.generate',
        }, always_rebuild=True, hidden=True)
    def srcs(self, cwd, noddr, mig):
        """RTL + verification sources including DDR3"""
        r = Result()
        r.design_srcs = noddr.design_srcs
        r.defines = noddr.defines | {'WITH_EXT_DRAM':'1'}
        r.include_dirs = noddr.include_dirs + mig.include_dirs
        r.tb_srcs = noddr.tb_srcs + mig.sim_verilog
        r.xcis = noddr.xcis + [mig.xci]
        return r

    @task(requires={"srcs":".srcs_noddr"})
    def lint(self, cwd, srcs):
        """Run static code quality assessment"""
        rules = [
            'always-comb',
            'always-comb-blocking',
            'always-ff-non-blocking',
            'case-missing-default',
            'explicit-function-lifetime',
            'explicit-function-task-parameter-type',
            'explicit-parameter-storage-type',
            'explicit-task-lifetime',
            'forbid-consecutive-null-statements',
            'forbid-defparam',
            'forbid-line-continuations',
            'generate-label',
            'module-begin-block',
            'module-filename',
            'module-parameter',
            'module-port',
            'one-module-per-file',
            'package-filename',
            'packed-dimensions-range-ordering',
            #'port-name-suffix',
            'undersized-binary-literal',
            'v2001-generate-begin',
            'void-cast',
        ]
        try:
            subprocess.check_call(['verible-verilog-lint', '--ruleset', 'none', '--rules', ",".join(rules)]+srcs.design_srcs, cwd=cwd)
        except subprocess.CalledProcessError as e:
            print(f"WARNING: verible-verilog-lint returned {e.returncode} errors.")
        else:
            print("Lint returned no errors.")
