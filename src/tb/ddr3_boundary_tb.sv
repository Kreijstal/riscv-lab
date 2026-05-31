// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2026 RVLab Contributors

`timescale 1ps / 1ps

module ddr3_boundary_tb;

`ifdef VERILATOR
  glbl glbl();
`endif

  localparam int CONTROLLER_CLK_PERIOD = 10_000;
  localparam int DDR3_CLK_PERIOD = 2_500;
  localparam int ROW_BITS = 15;
  localparam int COL_BITS = 10;
  localparam int BA_BITS = 3;
  localparam int BYTE_LANES = 2;
  localparam int AUX_WIDTH = 15;
  localparam int WB_ADDR_BITS = ROW_BITS + COL_BITS + BA_BITS - $clog2(4 * 2);
  localparam int WB_DATA_BITS = 8 * BYTE_LANES * 4 * 2;
  localparam int WB_SEL_BITS = WB_DATA_BITS / 8;

  logic controller_clk = 1'b0;
  logic ddr3_clk = 1'b0;
  logic ref_clk = 1'b0;
  logic ddr3_clk_90 = 1'b0;
  logic rst_n = 1'b0;

  wire [15:0] ddr3_dq;
  wire [ 1:0] ddr3_dqs_n;
  wire [ 1:0] ddr3_dqs_p;
  wire [14:0] ddr3_addr;
  wire [ 2:0] ddr3_ba;
  wire        ddr3_ras_n;
  wire        ddr3_cas_n;
  wire        ddr3_we_n;
  wire        ddr3_reset_n;
  wire [ 0:0] ddr3_ck_p;
  wire [ 0:0] ddr3_ck_n;
  wire [ 0:0] ddr3_cke;
  wire [ 0:0] ddr3_cs_n;
  wire [ 1:0] ddr3_dm;
  wire [ 0:0] ddr3_odt;

  wire        wb_stall;
  wire        wb_ack;
  wire        wb_err;
  wire [WB_DATA_BITS-1:0] wb_data;
  wire [AUX_WIDTH-1:0] wb_aux;
  wire        wb2_stall;
  wire        wb2_ack;
  wire [31:0] wb2_data;
  wire        calib_complete;
  wire [31:0] debug1;

  always #(CONTROLLER_CLK_PERIOD / 2) controller_clk = ~controller_clk;
  always #(DDR3_CLK_PERIOD / 2) ddr3_clk = ~ddr3_clk;
  always #2500 ref_clk = ~ref_clk;

  initial begin
    #(DDR3_CLK_PERIOD / 4);
    forever #(DDR3_CLK_PERIOD / 2) ddr3_clk_90 = ~ddr3_clk_90;
  end

  initial begin
    #1_000_000;
    rst_n = 1'b1;
  end

  ddr3_top #(
    .CONTROLLER_CLK_PERIOD(CONTROLLER_CLK_PERIOD),
    .DDR3_CLK_PERIOD(DDR3_CLK_PERIOD),
    .ROW_BITS(ROW_BITS),
    .COL_BITS(COL_BITS),
    .BA_BITS(BA_BITS),
    .BYTE_LANES(BYTE_LANES),
    .AUX_WIDTH(AUX_WIDTH),
`ifndef SYNTHESIS
    .MICRON_SIM(1),
`endif
    .ODELAY_SUPPORTED(0),
    .SECOND_WISHBONE(0),
    .ECC_ENABLE(0),
    .WB_ERROR(0),
    .BIST_MODE(0)
  ) ddr_i (
    .i_controller_clk(controller_clk),
    .i_ddr3_clk(ddr3_clk),
    .i_ref_clk(ref_clk),
    .i_ddr3_clk_90(ddr3_clk_90),
    .i_rst_n(rst_n),

    .i_wb_cyc(1'b1),
    .i_wb_stb(1'b0),
    .i_wb_we(1'b0),
    .i_wb_addr({WB_ADDR_BITS{1'b0}}),
    .i_wb_data({WB_DATA_BITS{1'b0}}),
    .i_wb_sel({WB_SEL_BITS{1'b0}}),
    .i_aux({AUX_WIDTH{1'b0}}),
    .o_wb_stall(wb_stall),
    .o_wb_ack(wb_ack),
    .o_wb_err(wb_err),
    .o_wb_data(wb_data),
    .o_aux(wb_aux),

    .i_wb2_cyc(1'b0),
    .i_wb2_stb(1'b0),
    .i_wb2_we(1'b0),
    .i_wb2_addr('0),
    .i_wb2_data('0),
    .i_wb2_sel('0),
    .o_wb2_stall(wb2_stall),
    .o_wb2_ack(wb2_ack),
    .o_wb2_data(wb2_data),

    .o_ddr3_clk_p(ddr3_ck_p),
    .o_ddr3_clk_n(ddr3_ck_n),
    .o_ddr3_reset_n(ddr3_reset_n),
    .o_ddr3_cke(ddr3_cke),
    .o_ddr3_cs_n(ddr3_cs_n),
    .o_ddr3_ras_n(ddr3_ras_n),
    .o_ddr3_cas_n(ddr3_cas_n),
    .o_ddr3_we_n(ddr3_we_n),
    .o_ddr3_addr(ddr3_addr),
    .o_ddr3_ba_addr(ddr3_ba),
    .io_ddr3_dq(ddr3_dq),
    .io_ddr3_dqs(ddr3_dqs_p),
    .io_ddr3_dqs_n(ddr3_dqs_n),
    .o_ddr3_dm(ddr3_dm),
    .o_ddr3_odt(ddr3_odt),

    .o_calib_complete(calib_complete),
    .o_debug1(debug1),
    .i_user_self_refresh(1'b0),
    .uart_tx()
  );

  ddr3 ddr3_model_i (
    .rst_n  (ddr3_reset_n),
    .ck     (ddr3_ck_p),
    .ck_n   (ddr3_ck_n),
    .cke    (ddr3_cke),
    .cs_n   (ddr3_cs_n),
    .ras_n  (ddr3_ras_n),
    .cas_n  (ddr3_cas_n),
    .we_n   (ddr3_we_n),
    .dm_tdqs(ddr3_dm),
    .ba     (ddr3_ba),
    .addr   (ddr3_addr),
    .dq     (ddr3_dq),
    .dqs    (ddr3_dqs_p),
    .dqs_n  (ddr3_dqs_n),
    .tdqs_n (),
    .odt    (ddr3_odt)
  );

  initial begin
    longint unsigned timeout_ps;

    timeout_ps = 64'd5_000_000_000;
    void'($value$plusargs("ddr_boundary_timeout_ps=%d", timeout_ps));

    $display("ddr3_boundary_tb: waiting up to %0d ps for calibration.", timeout_ps);
    #(timeout_ps);
    $fatal(1, "ddr3_boundary_tb: timeout, calib_complete=%0b debug1=0x%08x", calib_complete, debug1);
  end

  always @(posedge controller_clk) begin
    if (calib_complete) begin
      $display("ddr3_boundary_tb: calibration complete at %0t, debug1=0x%08x", $time, debug1);
      $finish;
    end
  end

  logic [4:0] last_calib_state = 5'h1f;
  int dqs_debug_count = 0;
  int dqs_edge_debug_count = 0;
  always @(posedge controller_clk) begin
    if (rst_n && debug1[4:0] != last_calib_state) begin
      $display("ddr3_boundary_tb: calib_state=0x%02x at %0t", debug1[4:0], $time);
      if (debug1[4:0] == 5'h04 && dqs_debug_count < 64) begin
        $display("ddr3_boundary_tb: lane=%0d idelay_dqs=%0d idelay_data=%0d phy_rst=%b dqs_tri=%b os_tq=%b os_oq=%b pad_dqs=%b/%b read_dqs=%b delayed_dqs=%b iserdes_dqs=0x%04x dqs0_shift=0x%02x dqs0_q=%b%b%b%b%b%b%b%b dqs_store=0x%010x",
          ddr_i.ddr3_controller_inst.lane,
          ddr_i.ddr3_controller_inst.idelay_dqs_cntvaluein[ddr_i.ddr3_controller_inst.lane],
          ddr_i.ddr3_controller_inst.idelay_data_cntvaluein[ddr_i.ddr3_controller_inst.lane],
          ddr_i.ddr3_phy_inst.sync_rst,
          ddr_i.dqs_tri_control,
          ddr_i.ddr3_phy_inst.oserdes_dqs_tri_control,
          ddr_i.ddr3_phy_inst.oserdes_dqs,
          ddr3_dqs_p,
          ddr3_dqs_n,
          ddr_i.ddr3_phy_inst.read_dqs,
          ddr_i.ddr3_phy_inst.idelay_dqs,
          ddr_i.iserdes_dqs,
          ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.sample_shift,
          ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.Q8,
          ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.Q7,
          ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.Q6,
          ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.Q5,
          ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.Q4,
          ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.Q3,
          ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.Q2,
          ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.Q1,
          ddr_i.ddr3_controller_inst.dqs_store);
        dqs_debug_count++;
      end
      last_calib_state <= debug1[4:0];
    end
  end

  always @(ddr3_dqs_p or ddr3_dqs_n or ddr_i.ddr3_phy_inst.read_dqs or ddr_i.ddr3_phy_inst.idelay_dqs) begin
    if (rst_n && debug1[4:0] == 5'h03 && dqs_edge_debug_count < 80) begin
      $display("ddr3_boundary_tb: dqs_edge t=%0t pad=%b/%b read=%b delayed=%b",
        $time,
        ddr3_dqs_p,
        ddr3_dqs_n,
        ddr_i.ddr3_phy_inst.read_dqs,
        ddr_i.ddr3_phy_inst.idelay_dqs);
      $display("ddr3_boundary_tb: dqs0_model t=%0t clk=%b ddly=%b shift=0x%02x q=%b%b%b%b%b%b%b%b",
        $time,
        ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.CLK,
        ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.DDLY,
        ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.sample_shift,
        ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.Q8,
        ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.Q7,
        ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.Q6,
        ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.Q5,
        ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.Q4,
        ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.Q3,
        ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.Q2,
        ddr_i.ddr3_phy_inst.genblk7[0].ISERDESE2_dqs.Q1);
      dqs_edge_debug_count++;
    end
  end

endmodule
