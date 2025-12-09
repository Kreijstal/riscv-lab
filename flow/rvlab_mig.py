# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 RVLab Contributors

from pydesignflow import Block, task, Result
from .tools.vivado import Vivado
import shutil
import re

class RvlabMig(Block):
    """
    Xilinx DDR3 Memory Interface Generator (MIG) IP
    """
    name = "rvlab_mig"

    part = "xc7a200tsbg484-1"
    ip_vlnv = "xilinx.com:ip:mig_7series:4.2"

    def setup(self):
        self.src_dir = self.flow.base_dir / "src"
        self.design_dir = self.src_dir / "design"

    @task()
    def generate(self, cwd):
        """Generate IP"""

        r = Result()
     
        #cfg_files = [
        #    self.design_dir / f"ip/rvlab_mig.xci",        
        #    self.design_dir / f"ip/mig_a.prj",
        #    #self.design_dir / f"ip/mig_b.prj",
        #]

        #for f in cfg_files:
        #    shutil.copy(f, cwd / f.name)

        properties = {
            "CONFIG.XML_INPUT_FILE": self.design_dir / f"ip/mig_a.prj",
        }

        with Vivado(cwd=cwd) as t:
            t.set_part(self.part)
            #t.read_ip(r.xci)
            t.create_ip(vlnv=self.ip_vlnv, module_name=self.name, dir=cwd)

            ip = t.get_ips(self.name)
            ip.set_property(dict=properties)
            ip.generate_target("all")
            ip.synth_ip()

        ip_dir = cwd / 'rvlab_mig'
        r.xci = ip_dir / f"rvlab_mig.xci"

        user_design_dir = ip_dir / 'rvlab_mig/user_design'
        example_design_dir = ip_dir / "rvlab_mig/example_design"
            
        r.sim_verilog = [
            user_design_dir / 'rtl/rvlab_mig.v',
            user_design_dir / 'rtl/rvlab_mig_mig_sim.v',
            ]
        ddr3_model_parameters_vh = example_design_dir / 'sim/ddr3_model_parameters.vh'

        r.sim_verilog += list((user_design_dir / 'rtl').glob('*/*.v'))
        r.sim_verilog += [example_design_dir / 'sim/ddr3_model.sv']
        #r.sim_verilog += list((example_design_dir / 'sim').glob('*.v'))
        #r.sim_verilog += list((example_design_dir / 'rtl').glob('**/*.v'))
            
        r.include_dirs = [example_design_dir / 'sim']

        r.xdc = user_design_dir / 'constraints/rvlab_mig.xdc'
        r.xdc_ooc = user_design_dir / 'constraints/rvlab_mig_ooc.xdc'

        r.dcp = ip_dir / "rvlab_mig.dcp"
        
        ddr3_model_disable_debug(ddr3_model_parameters_vh)
        
        for v in r.sim_verilog:
            assert v.exists()
        for d in r.include_dirs:
            assert d.exists()
        assert r.xdc.exists()
        assert r.xdc_ooc.exists()
        assert r.dcp.exists()

        return r

def ddr3_model_disable_debug(filename):
    """
    Repalces DEBUG = 1 with DEBUG = 0 in ddr_model.sv.
    """
    with open(filename, 'r') as f:
        d = f.read()
    d = re.sub(r"parameter\s+DEBUG\s+=\s+1;", 'parameter DEBUG = 0;', d)
    with open(filename, 'w') as f:
        f.write(d)
