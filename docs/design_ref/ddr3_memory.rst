DDR3 Memory
===========

The Nexys Video board comes with 512~MB DDR3 memory.

The Xilinx Memory Interface Generator (MIG) 7 is used for interfacing. Docs: https://support.xilinx.com/s/article/46226?language=en_US

To speed up RTL simulation, the MIG is by default not included in RTL simulations. The MIG is always used in synthesis and therefore always present in netlist simulations.

- 0x80000000 / 0x90000000 are strangely mirrored. This seems like a MIG / memory problem. This means that currently, only 256 MB DDR memory are accessible.