// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: 2024 RVLab Contributors

module rvlab_tlul_ddr (
  input logic clk_i,  // sys_clk
  input logic rst_ni,

  input logic clk_100mhz_buffered_i,
  input logic clk_200mhz_i,

  // TL-UL slave interface
  input  tlul_pkg::tl_h2d_t tl_i,
  output tlul_pkg::tl_d2h_t tl_o,
  input  tlul_pkg::tl_h2d_t tl_ctrl_i,
  output tlul_pkg::tl_d2h_t tl_ctrl_o,

  inout  wire [15:0] ddr3_dq,
  inout  wire [ 1:0] ddr3_dqs_n,
  inout  wire [ 1:0] ddr3_dqs_p,
  output wire [14:0] ddr3_addr,
  output wire [ 2:0] ddr3_ba,
  output wire        ddr3_ras_n,
  output wire        ddr3_cas_n,
  output wire        ddr3_we_n,
  output wire        ddr3_reset_n,
  output wire [ 0:0] ddr3_ck_p,
  output wire [ 0:0] ddr3_ck_n,
  output wire [ 0:0] ddr3_cke,
  output wire [ 1:0] ddr3_dm,
  output wire [ 0:0] ddr3_odt
);

  typedef struct packed {
    logic         rst_n;
    logic [28:0]  app_addr;
    logic [2:0]   app_cmd;
    logic         app_en;
    logic [127:0] app_wdf_data;
    logic         app_wdf_end;
    logic [15:0]  app_wdf_mask;
    logic         app_wdf_wren;
    logic         app_sr_req;
    logic         app_ref_req;
    logic         app_zq_req;
  } core2mig_t;

  typedef struct packed {
    logic         mig_present;
    logic [127:0] app_rd_data;
    logic         app_rd_data_end;
    logic         app_rd_data_valid;
    logic         app_rdy;
    logic         app_wdf_rdy;
    logic         app_sr_active;
    logic         app_ref_ack;
    logic         app_zq_ack;
    logic         ui_clk;
    logic         ui_clk_sync_rst;
    logic         init_calib_complete;
    logic [11:0]  device_temp;
  } mig2core_t;

  typedef struct packed {
    logic [24:0]  addr;
    logic [127:0] wdata;
    logic         wen;
  } cdc_sys2mig_t;

  cdc_sys2mig_t cdc_sys2mig_sys;
  cdc_sys2mig_t cdc_sys2mig_mig;

  logic cdc_sys2mig_wvalid;
  logic cdc_sys2mig_wready;
  logic cdc_sys2mig_rvalid;
  logic cdc_sys2mig_rready;

  logic cdc_sys_rdata_valid;
  logic [127:0] cdc_sys_rdata;

  // Xilinx MIG instance
  // -------------------

  mig2core_t mig2core;
  core2mig_t core2mig;

`ifdef WITH_EXT_DRAM
  assign mig2core.mig_present = '1;

  rvlab_mig mig_i (
    .ddr3_dq,
    .ddr3_dqs_n,
    .ddr3_dqs_p,
    .ddr3_addr,
    .ddr3_ba,
    .ddr3_ras_n,
    .ddr3_cas_n,
    .ddr3_we_n,
    .ddr3_reset_n,
    .ddr3_ck_p,
    .ddr3_ck_n,
    .ddr3_cke,
    .ddr3_dm,
    .ddr3_odt,

    .sys_clk_i(clk_100mhz_buffered_i),
    .clk_ref_i(clk_200mhz_i),
    .sys_rst  (core2mig.rst_n),

    .app_addr           (core2mig.app_addr),
    .app_cmd            (core2mig.app_cmd),
    .app_en             (core2mig.app_en),
    .app_wdf_data       (core2mig.app_wdf_data),
    .app_wdf_end        (core2mig.app_wdf_end),
    .app_wdf_mask       (core2mig.app_wdf_mask),
    .app_wdf_wren       (core2mig.app_wdf_wren),
    .app_sr_req         (core2mig.app_sr_req),
    .app_ref_req        (core2mig.app_ref_req),
    .app_zq_req         (core2mig.app_zq_req),
    .app_rd_data        (mig2core.app_rd_data),
    .app_rd_data_end    (mig2core.app_rd_data_end),
    .app_rd_data_valid  (mig2core.app_rd_data_valid),
    .app_rdy            (mig2core.app_rdy),
    .app_wdf_rdy        (mig2core.app_wdf_rdy),
    .app_sr_active      (mig2core.app_sr_active),
    .app_ref_ack        (mig2core.app_ref_ack),
    .app_zq_ack         (mig2core.app_zq_ack),
    .ui_clk             (mig2core.ui_clk),
    .ui_clk_sync_rst    (mig2core.ui_clk_sync_rst),
    .init_calib_complete(mig2core.init_calib_complete),
    .device_temp        (mig2core.device_temp)
  );
`else
  assign mig2core     = '{mig_present: '0, default: '0};

  // Make sure all output signals are somehow valid, in case someone ties to
  // build a bitstream of the design without DDR.

  assign ddr3_addr    = '0;
  assign ddr3_ba      = '0;
  assign ddr3_ras_n   = '1;
  assign ddr3_cas_n   = '1;
  assign ddr3_we_n    = '1;
  assign ddr3_reset_n = '0;

  assign ddr3_ck_p    = '1;
  assign ddr3_ck_n    = '0;
  assign ddr3_cke     = '0;

  assign ddr3_dm      = '0;

  // ddr3_dq, ddr3_dqs_n, ddr3_dqs_p, ddr3_dm are unused and pulled down (?) by default.

`endif


  // Control & status TL-UL device
  // -----------------------------

  ddr_ctrl_reg_pkg::ddr_ctrl_hw2reg_t ctrl_hw2reg;
  ddr_ctrl_reg_pkg::ddr_ctrl_reg2hw_t ctrl_reg2hw;
  logic calib_complete_sync;

  ddr_ctrl_reg_top ctrl_reg_i (
    .clk_i,
    .rst_ni,
    .tl_o     (tl_ctrl_o),
    .tl_i     (tl_ctrl_i),
    .hw2reg   (ctrl_hw2reg),
    .reg2hw   (ctrl_reg2hw),
    .devmode_i('0)
  );

  assign core2mig.rst_n               = ctrl_reg2hw.ctrl.q;
  assign ctrl_hw2reg.status.present.d = mig2core.mig_present;
  // Note: device_temp is not properly synced here!
  prim_flop_2sync #(
    .Width(1)
  ) calib_complete_sync_i (
    .clk_i,
    .rst_ni,
    // The calib_complete signal can be x during reset. To prevent x reads:
    .d(mig2core.ui_clk_sync_rst ? '0 : mig2core.init_calib_complete),
    .q(ctrl_hw2reg.status.calib_complete.d)
  );

  prim_flop_2sync #(
    .Width(12)
  ) device_temp_sync_i (
    .clk_i,
    .rst_ni,
    .d(mig2core.device_temp),
    .q(ctrl_hw2reg.temp.d)
  );


  // Answer TL-UL request using currently loaded block (block_data, block_addr)
  // --------------------------------------------------------------------------

  logic                                     req_pending;
  logic                                     req_finished;
  tlul_pkg::tl_a_op_e                       req_opcode;
  logic               [top_pkg::TL_SZW-1:0] req_size;
  logic               [top_pkg::TL_AIW-1:0] req_source;
  logic               [ top_pkg::TL_AW-1:0] req_address;
  logic               [top_pkg::TL_DBW-1:0] req_mask;
  logic               [ top_pkg::TL_DW-1:0] req_data;

  logic               [              127:0] block_data;
  logic               [               24:0] block_addr;
  logic                                     block_dirty;
  logic                                     hit;

  logic               [               31:0] write_mask_word;
  logic               [              127:0] write_mask;
  logic               [              127:0] write_data;
  logic               [               24:0] req_block_addr;

  assign req_finished = tl_o.d_valid && tl_i.d_ready;
  assign req_block_addr = req_address[28:4];
  assign hit = (req_block_addr == block_addr);
  assign tl_o.a_ready = !req_pending;
  assign tl_o.d_opcode = (req_opcode == tlul_pkg::Get) ? tlul_pkg::AccessAckData:tlul_pkg::AccessAck;
  assign tl_o.d_size = req_size;
  assign tl_o.d_param = '0;
  assign tl_o.d_sink = '0;
  assign tl_o.d_source = req_source;
  assign tl_o.d_user = '0;
  assign tl_o.d_error = '0;
  assign tl_o.d_valid = req_pending && hit;


  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      req_pending <= '0;
      req_opcode  <= tlul_pkg::Get;
      req_size    <= '0;
      req_source  <= '0;
      req_address <= '0;
      req_mask    <= '0;
      req_data    <= '0;
    end else begin
      if (tl_i.a_valid && tl_o.a_ready) begin
        req_pending <= '1;
        req_opcode  <= tl_i.a_opcode;
        req_size    <= tl_i.a_size;
        req_source  <= tl_i.a_source;
        req_address <= tl_i.a_address;
        req_mask    <= tl_i.a_mask;
        req_data    <= tl_i.a_data;
      end
      if (req_finished) begin
        req_pending <= '0;
      end
    end
  end

  // Byte/hword/word read & write logic
  // ----------------------------------

  logic [3:0] byte_addr;
  logic [2:0] hword_addr;
  logic [1:0] word_addr;

  assign byte_addr  = req_address[3:0];
  assign hword_addr = req_address[3:1];
  assign word_addr  = req_address[3:2];

  always_comb begin
    tl_o.d_data            = '0;

    write_mask_word[7:0]   = req_mask[0] ? '1 : '0;
    write_mask_word[15:8]  = req_mask[1] ? '1 : '0;
    write_mask_word[23:16] = req_mask[2] ? '1 : '0;
    write_mask_word[31:24] = req_mask[3] ? '1 : '0;

    write_mask             = '0;
    write_data             = '0;

    case (req_size)
      0: begin  // byte access
        tl_o.d_data[7:0]           = block_data[byte_addr*8+:8];
        write_mask[byte_addr*8+:8] = write_mask_word[7:0];
        write_data[byte_addr*8+:8] = req_data[7:0];
      end
      1: begin  // hword access
        tl_o.d_data[15:0]             = block_data[hword_addr*16+:16];
        write_mask[hword_addr*16+:16] = write_mask_word[15:0];
        write_data[hword_addr*16+:16] = req_data[15:0];
      end
      2: begin  // word access
        tl_o.d_data[31:0]            = block_data[word_addr*32+:32];
        write_mask[word_addr*32+:32] = write_mask_word[31:0];
        write_data[word_addr*32+:32] = req_data[31:0];
      end
      default: begin
        tl_o.d_data = '0;
      end
    endcase
  end

  // Block manager (BM), transfers blocks from / to MIG
  // --------------------------------------------------

  logic block_load_streambuf;
  logic block_load_rdata;
  logic modify;
  logic [127:0] block_next;
  logic block_next_requested;
  logic sys2mig_requests_next_block;
  logic block_next_valid;

  assign modify = req_pending && hit && (req_opcode == tlul_pkg::PutFullData || req_opcode == tlul_pkg::PutPartialData);
  assign cdc_sys2mig_sys.wdata = block_data;

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      block_data  <= '0;
      block_addr  <= '0;
      block_dirty <= '0;
    end else begin
      if (modify) begin
        block_data  <= (block_data & ~write_mask) | (write_data & write_mask);
        block_dirty <= '1;
      end
      if (block_load_streambuf || block_load_rdata) begin
        block_addr  <= req_block_addr;
        block_dirty <= '0;
      end
      if (block_load_streambuf) begin
        block_data <= block_next;
      end
      if (block_load_rdata) begin
        block_data <= cdc_sys_rdata;
      end
    end
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      block_next           <= '0;
      block_next_valid     <= '1;
      block_next_requested <= '0;
    end else begin
      if (block_load_streambuf || block_load_rdata) begin
        block_next_valid <= '0;
      end
      if (cdc_sys_rdata_valid && block_next_requested) begin
        block_next_requested <= '0;
        block_next_valid     <= '1;
        block_next           <= cdc_sys_rdata;
      end
      if (sys2mig_requests_next_block && cdc_sys2mig_wready) begin
        block_next_requested <= '1;
      end
    end
  end


  typedef enum {
    BM_IDLE,
    BM_WRITEBACK,
    BM_READ,
    BM_WAIT
  } bm_fsm_e;

  bm_fsm_e bm_state, bm_next;

  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
      bm_state <= BM_IDLE;
    end else begin
      bm_state <= bm_next;
    end
  end

  always_comb begin
    bm_next              = bm_state;
    block_load_streambuf = '0;
    block_load_rdata     = '0;

    case (bm_state)
      BM_IDLE: begin
        if (req_pending && !hit) begin
          if (block_dirty) begin
            bm_next = BM_WRITEBACK;
          end else begin
            if (req_block_addr == block_addr + 1 && block_next_valid) begin
              block_load_streambuf = '1;
              bm_next              = BM_IDLE;
            end else begin
              bm_next = BM_READ;
            end
          end
        end
      end
      BM_WRITEBACK: begin
        if (cdc_sys2mig_wready) begin
          if (req_block_addr == block_addr + 1 && block_next_valid) begin
            block_load_streambuf = '1;
            bm_next              = BM_IDLE;
          end else begin
            bm_next = BM_READ;
          end
        end
      end
      BM_READ: begin
        if (cdc_sys2mig_wready) begin
          bm_next = BM_WAIT;
        end
      end
      BM_WAIT: begin
        if (cdc_sys_rdata_valid && !block_next_requested) begin
          block_load_rdata = '1;
          bm_next          = BM_IDLE;
        end
      end
      default: begin end
    endcase
  end

  always_comb begin
    cdc_sys2mig_sys.wen         = '0;
    cdc_sys2mig_sys.addr        = '0;
    cdc_sys2mig_wvalid          = '0;
    sys2mig_requests_next_block = '0;

    case (bm_next)
      BM_WRITEBACK: begin
        cdc_sys2mig_wvalid   = '1;
        cdc_sys2mig_sys.wen  = '1;
        cdc_sys2mig_sys.addr = block_addr;
      end
      BM_READ: begin
        cdc_sys2mig_wvalid   = '1;
        cdc_sys2mig_sys.wen  = '0;
        cdc_sys2mig_sys.addr = req_block_addr;
      end
      BM_IDLE: begin
        if (!block_next_valid && !block_next_requested) begin
          cdc_sys2mig_wvalid          = '1;
          cdc_sys2mig_sys.wen         = '0;
          cdc_sys2mig_sys.addr        = req_block_addr + 1;
          sys2mig_requests_next_block = '1;
        end
      end
      default: begin end
    endcase
  end


  // Clock Domain Crossing FIFOs (System Clock <-> MIG Clock)
  // --------------------------------------------------------

  logic mig_clk, mig_rst_n;

  assign mig_clk   = mig2core.ui_clk;
  assign mig_rst_n = !mig2core.ui_clk_sync_rst;

  prim_fifo_async #(
    .Width($size(cdc_sys2mig_sys)),
    .Depth(3)
  ) fifo_sys2mig_i (
    .clk_wr_i (clk_i),
    .rst_wr_ni(rst_ni),
    .wvalid   (cdc_sys2mig_wvalid),  // in
    .wready   (cdc_sys2mig_wready),  // out
    .wdata    (cdc_sys2mig_sys),     // in
    .wdepth   (),                    // out

    .clk_rd_i (mig_clk),
    .rst_rd_ni(mig_rst_n),
    .rvalid   (cdc_sys2mig_rvalid),  // out
    .rready   (cdc_sys2mig_rready),  // in
    .rdata    (cdc_sys2mig_mig),     // out
    .rdepth   ()                     // out
  );

  prim_fifo_async #(
    .Width($size(cdc_sys_rdata)),
    .Depth(3)
  ) fifo_rdata_i (
    .clk_wr_i (mig_clk),
    .rst_wr_ni(mig_rst_n),
    .wvalid   (mig2core.app_rd_data_valid),  // in
    .wready   (),                            // out
    .wdata    (mig2core.app_rd_data),        // in
    .wdepth   (),                            // out

    .clk_rd_i (clk_i),
    .rst_rd_ni(rst_ni),
    .rvalid   (cdc_sys_rdata_valid),  // out
    .rready   ('1),                   // in
    .rdata    (cdc_sys_rdata),        // out
    .rdepth   ()                      // out
  );

  // MIG clock domain
  // ----------------

  localparam bit [3:0] CMD_WRITE = 3'b000;
  localparam bit [3:0] CMD_READ = 3'b001;

  cdc_sys2mig_t sys2mig_req;
  cdc_sys2mig_t sys2mig_req_saved;

  assign core2mig.app_wdf_data = sys2mig_req.wdata;
  assign core2mig.app_wdf_end  = core2mig.app_wdf_wren;
  assign core2mig.app_wdf_mask = '0;
  assign core2mig.app_sr_req   = '0;
  assign core2mig.app_ref_req  = '0;
  assign core2mig.app_zq_req   = '0;
  // app_addr addresses 16-bit words (native memory width)
  // the address MSB is irrelevant, as it is used as 1-bit rank address even
  // though only a single chip is connected. this seems like a design mistake in the mig.
  // see: https://stackoverflow.com/questions/59878013/confusion-about-ddr3-addressing-via-mig-in-kc705
  assign core2mig.app_addr     = {1'b0, sys2mig_req.addr, 3'b000};
  assign core2mig.app_cmd      = sys2mig_req.wen ? CMD_WRITE : CMD_READ;

  // sys2mig_req storage:

  always_ff @(posedge mig_clk, negedge mig_rst_n) begin
    if (!mig_rst_n) begin
      sys2mig_req_saved <= '{default: '0};
    end else begin
      if (cdc_sys2mig_rvalid && cdc_sys2mig_rready) begin
        sys2mig_req_saved <= cdc_sys2mig_mig;
      end
    end
  end

  always_comb begin
    if (cdc_sys2mig_rvalid && cdc_sys2mig_rready) begin
      sys2mig_req = cdc_sys2mig_mig;
    end else begin
      sys2mig_req = sys2mig_req_saved;
    end
  end

  // app_rdy, app_wdf_rdy flip-flop:

  logic app_rdy_last;
  logic app_wdf_rdy_last;

  always_ff @(posedge mig_clk, negedge mig_rst_n) begin
    if (!mig_rst_n) begin
      app_rdy_last     <= '0;
      app_wdf_rdy_last <= '0;
    end else begin
      app_rdy_last     <= mig2core.app_rdy;
      app_wdf_rdy_last <= mig2core.app_wdf_rdy;
    end
  end

  // MIG adapter (MA) FSM:

  typedef enum {
    MA_IDLE,
    MA_CMD,
    MA_WDATA
  } ma_fsm_e;

  ma_fsm_e ma_state, ma_next;

  always_ff @(posedge mig_clk, negedge mig_rst_n) begin
    if (!mig_rst_n) begin
      ma_state <= MA_IDLE;
    end else begin
      ma_state <= ma_next;
    end
  end

  always_comb begin
    ma_next               = ma_state;
    core2mig.app_en       = '0;
    core2mig.app_wdf_wren = '0;
    cdc_sys2mig_rready    = '0;

    case (ma_state)
      MA_IDLE: begin
        if (cdc_sys2mig_rvalid) begin
          cdc_sys2mig_rready = '1;
          core2mig.app_en    = '1;
          ma_next            = MA_CMD;
        end
      end
      MA_CMD: begin
        if (!app_rdy_last) begin
          core2mig.app_en = '1;
        end else begin
          if (sys2mig_req.wen) begin
            ma_next               = MA_WDATA;
            core2mig.app_wdf_wren = '1;
          end else begin
            ma_next = MA_IDLE;
          end
        end
      end
      MA_WDATA: begin
        if (!app_wdf_rdy_last) begin
          core2mig.app_wdf_wren = '1;
        end else begin
          ma_next = MA_IDLE;
        end
      end
      default: begin
        ma_next = MA_IDLE;
      end
    endcase
  end

endmodule
