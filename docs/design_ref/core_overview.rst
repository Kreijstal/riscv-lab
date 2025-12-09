.. _`Core Overview`:

Core Overview
=============

The following block diagram gives an overview of the **rvlab_core** module.

.. figure:: rvlab_core.svg
   :width: 100%

   rvlab_core block diagram

H indicates a TL-UL host port, D a TL-UL device port. 

The system clock and reset are provided to rvlab_core as **clk_i** and **rst_ni**. Please do not use the alternative reset signal rst_dbg_ni outside the rvlab_debug module. Consult :ref:`clocks_resets` for details.

Components:

- **rvlab_cpu** -- contains the Ibex CPU implementing the RV32IMC instruction set
- **xbar_main** -- main crossbar switch (fast accesses)
- **xbar_peri** -- periphery crossbar switch (slower accesses)
- **student** -- module for exercises and project implementation
- **bram_main** -- main block RAM for instruction and data storage
- **rvlab_debug** -- contains the RISC-V debug module, and JTAG debug transport module, can interrupt CPU using non-maskable debug_req, provides direct system bus access (SBA) to debug host
- **rvlab_timer** -- simple timer module, can raise interrupt request irq_timer
- **regdemo** -- register generation demo module

The tl_ddr_i/tl_ddr_o and tl_ddr_ctrl_i/tl_ddr_ctrl_o ports connect to a DDR3 memory controller instantiated outside of rvlab_core.

The Ibex core used in the RISC-V Lab stems from commit `183ae4ad4f346336040cdd78b11cb3c08b54a167 <https://github.com/lowRisc/Ibex/commit/183ae4ad4f346336040cdd78b11cb3c08b54a167>`_ (Jan 28, 2020) of the lowRISC/Ibex Git repository. More recent versions of Ibex have been found less suitable for the lab, as a significant amount of complexity has been added that is not of use for this lab.
The corresponding OpenTitan commit is approximately `19f8eca67e8b4213838ee05546ab439cbf5f8930 <https://github.com/lowRISC/opentitan/commit/19f8eca67e8b4213838ee05546ab439cbf5f8930>`_ (Feb 4, 2020).

To obtain the most accurate documentation of Ibex and OpenTitan for the purposes of the RISC-V Lab, please checkout the aforementioned commits of Ibex and OpenTitan. The latest online documentation of Ibex and OpenTitan differs substantially in some aspects.

Student module
--------------

The student module is euqipped with following inputs / outputs:

- **tl_device_peri_i/tl_device_peri_o** -- TL-UL device port connected to xbar_peri
- **tl_device_fast_i/tl_device_fast_o** -- TL-UL device port connected to xbar_main
- **tl_host_i/tl_host_o** -- TL-UL host port connected to xbar_main
- **irq_o** -- interrupt output (level sensitive) connected to irq_external of the CPU
- **userio_i/userio_o** (types userio_board2fpga_t and userio_fpga2board_t) -- connects external hardware to student module, see :ref:`fpga_board`
