// Copyright lowRISC contributors.
// SPDX-FileCopyrightText: 2024 RVLab Contributors
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modified from 'opentitan/hw/ip/rv_core_ibex/rtl/rv_core_ibex.sv' for RVLab.

// 32 bit RISC-V core supporting the RV32I + optionally EMC instruction sets.
// Instruction and data bus are 32 bit wide TileLink-UL (TL-UL).

module rvlab_cpu (
  // Clock and Reset
  input logic clk_i,
  input logic rst_ni,

  input logic irq_external_i,
  input logic irq_timer_i,

  // Instruction memory interface
  output tlul_pkg::tl_h2d_t tl_i_o,
  input  tlul_pkg::tl_d2h_t tl_i_i,

  // Data memory interface
  output tlul_pkg::tl_h2d_t tl_d_o,
  input  tlul_pkg::tl_d2h_t tl_d_i,

  // Debug Interface
  input logic debug_req_i
);


  import tlul_pkg::*;
  import top_pkg::*;

  localparam int WordSize = $clog2(TL_DW / 8);

  // Instruction interface (internal)
  logic           instr_req;
  logic           instr_gnt;
  logic           instr_rvalid;
  logic    [31:0] instr_addr;
  logic    [31:0] instr_rdata;
  logic           instr_err;

  // Data interface (internal)
  logic           data_req;
  logic           data_gnt;
  logic           data_rvalid;
  logic           data_we;
  logic    [ 3:0] data_be;
  logic    [31:0] data_addr;
  logic    [31:0] data_wdata;
  logic    [31:0] data_rdata;
  logic           data_err;

  // Pipeline interfaces
  tl_h2d_t        instr_ibex2fifo;
  tl_d2h_t        instr_fifo2ibex;
  tl_h2d_t        data_ibex2fifo;
  tl_d2h_t        data_fifo2ibex;

  ibex_core #(
    .PMPEnable      ('0),
    .RV32E          ('0),
    .RV32M          ('1),
    .MultiplierImplementation("slow"),
    .DmHaltAddr     (32'h1E000800),
    .DmExceptionAddr(32'h1E000808)
  ) u_core_default (
    .clk_i,
    .rst_ni,
    .test_en_i     ('0),
    .hart_id_i     ('0),
    .boot_addr_i   (32'h00000000),
    .instr_req_o   (instr_req),
    .instr_gnt_i   (instr_gnt),
    .instr_rvalid_i(instr_rvalid),
    .instr_addr_o  (instr_addr),
    .instr_rdata_i (instr_rdata),
    .instr_err_i   (instr_err),
    .data_req_o    (data_req),
    .data_gnt_i    (data_gnt),
    .data_rvalid_i (data_rvalid),
    .data_we_o     (data_we),
    .data_be_o     (data_be),
    .data_addr_o   (data_addr),
    .data_wdata_o  (data_wdata),
    .data_rdata_i  (data_rdata),
    .data_err_i    (data_err),
    .irq_software_i('0),
    .irq_timer_i,
    .irq_external_i,
    .irq_fast_i    ('0),
    .irq_nm_i      ('0),
    .debug_req_i,
    .fetch_enable_i('1),
    .core_sleep_o  ()
  );

  //
  // Convert ibex data/instruction bus to TL-UL
  //

  tl_h2d_t tl_i_ibex2fifo;
  tl_d2h_t tl_i_fifo2ibex;
  tl_h2d_t tl_d_ibex2fifo;
  tl_d2h_t tl_d_fifo2ibex;

  // Generate a_source fields by toggling between 0 and 1
  logic tl_i_source, tl_d_source;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      {tl_i_source, tl_d_source} <= '0;
    end else begin
      if (instr_req && instr_gnt) tl_i_source <= !tl_i_source;
      if (data_req && data_gnt) tl_d_source <= !tl_d_source;
    end
  end

  // Convert core instruction interface to TL-UL
  // The outgoing address is always word aligned
  assign tl_i_ibex2fifo = '{
    a_valid: instr_req,
    a_opcode: tlul_pkg::Get,
    a_param: 3'h0,
    a_size: 2'(WordSize),
    a_mask: {TL_DBW{1'b1}},
    a_source: TL_AIW'(tl_i_source),
    a_address: {instr_addr[31:WordSize], {WordSize{1'b0}}},
    a_data: {TL_DW{1'b0}},
    a_user: '{default: '0},

    d_ready: 1'b1
  };

  assign instr_gnt = tl_i_fifo2ibex.a_ready & tl_i_ibex2fifo.a_valid;
  assign instr_rvalid = tl_i_fifo2ibex.d_valid;
  assign instr_rdata = tl_i_fifo2ibex.d_data;
  assign instr_err = tl_i_fifo2ibex.d_error;

  // Instruction fetch TL-UL FIFO
  tlul_fifo_sync #(
    .ReqPass ('1), // pipeline request
    .RspPass ('1), // passthrough response
    .ReqDepth(0),
    .RspDepth(0)
  ) fifo_i (
    .clk_i,
    .rst_ni,
    .tl_h_i     (tl_i_ibex2fifo),
    .tl_h_o     (tl_i_fifo2ibex),
    .tl_d_o     (tl_i_o),
    .tl_d_i     (tl_i_i),
    .spare_req_i(1'b0),
    .spare_req_o(),
    .spare_rsp_i(1'b0),
    .spare_rsp_o()
  );

  // Convert core data interface to TL-UL
  // The outgoing address is always word aligned.  If it's a write access that occupies
  // all lanes, then the operation is always PutFullData; otherwise it is always PutPartialData
  // When in partial opertaion, tlul allows writes smaller than the operation size, thus
  // size / mask information can be directly passed through
  assign tl_d_ibex2fifo = '{
          a_valid: data_req,
          a_opcode:
          (
          ~data_we
          ) ?
          tlul_pkg::Get
          : (
          data_be == 4'hf
          ) ?
          tlul_pkg::PutFullData
          :
          tlul_pkg::PutPartialData,
          a_param: 3'h0,
          a_size: 2'(WordSize),
          a_mask: data_be,
          a_source: TL_AIW'(tl_d_source),
          a_address: {data_addr[31:WordSize], {WordSize{1'b0}}},
          a_data: data_wdata,
          a_user: '{default: '0},

          d_ready: 1'b1
      };
  assign data_gnt = tl_d_fifo2ibex.a_ready & tl_d_ibex2fifo.a_valid;
  assign data_rvalid = tl_d_fifo2ibex.d_valid;
  assign data_rdata = tl_d_fifo2ibex.d_data;
  assign data_err = tl_d_fifo2ibex.d_error;


  // Load/store TL-UL FIFO
  tlul_fifo_sync #(
    .ReqPass ('1), // pipeline request
    .RspPass ('1), // passthrough response
    .ReqDepth(0),
    .RspDepth(0)
  ) fifo_d (
    .clk_i,
    .rst_ni,
    .tl_h_i     (tl_d_ibex2fifo),
    .tl_h_o     (tl_d_fifo2ibex),
    .tl_d_o     (tl_d_o),
    .tl_d_i     (tl_d_i),
    .spare_req_i(1'b0),
    .spare_req_o(),
    .spare_rsp_i(1'b0),
    .spare_rsp_o()
  );

endmodule
