onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Input / Output Signals}
add wave -noupdate -group JTAG /system_tb/board/jtag_tck_i
add wave -noupdate -group JTAG /system_tb/board/jtag_tdi_i
add wave -noupdate -group JTAG /system_tb/board/jtag_tdo_o
add wave -noupdate -group JTAG /system_tb/board/jtag_tms_i
add wave -noupdate -group JTAG /system_tb/board/jtag_trst_ni
add wave -noupdate -group JTAG /system_tb/board/jtag_srst_ni
add wave -noupdate -group DDR3 /system_tb/board/ddr3_dq
add wave -noupdate -group DDR3 /system_tb/board/ddr3_dqs_n
add wave -noupdate -group DDR3 /system_tb/board/ddr3_dqs_p
add wave -noupdate -group DDR3 /system_tb/board/ddr3_addr
add wave -noupdate -group DDR3 /system_tb/board/ddr3_ba
add wave -noupdate -group DDR3 /system_tb/board/ddr3_ras_n
add wave -noupdate -group DDR3 /system_tb/board/ddr3_cas_n
add wave -noupdate -group DDR3 /system_tb/board/ddr3_we_n
add wave -noupdate -group DDR3 /system_tb/board/ddr3_reset_n
add wave -noupdate -group DDR3 /system_tb/board/ddr3_ck_p
add wave -noupdate -group DDR3 /system_tb/board/ddr3_ck_n
add wave -noupdate -group DDR3 /system_tb/board/ddr3_cke
add wave -noupdate -group DDR3 /system_tb/board/ddr3_dm
add wave -noupdate -group DDR3 /system_tb/board/ddr3_odt
add wave -noupdate -group {User I/O} /system_tb/board/switch_i
add wave -noupdate -group {User I/O} /system_tb/board/uart_rx_out
add wave -noupdate -group {User I/O} /system_tb/board/uart_tx_in
add wave -noupdate -group {User I/O} /system_tb/board/ps2_clk
add wave -noupdate -group {User I/O} /system_tb/board/ps2_data
add wave -noupdate -group {User I/O} /system_tb/board/scl
add wave -noupdate -group {User I/O} /system_tb/board/sda
add wave -noupdate -group {User I/O} /system_tb/board/oled_sdin
add wave -noupdate -group {User I/O} /system_tb/board/oled_sclk
add wave -noupdate -group {User I/O} /system_tb/board/oled_dc
add wave -noupdate -group {User I/O} /system_tb/board/oled_res
add wave -noupdate -group {User I/O} /system_tb/board/oled_vbat
add wave -noupdate -group {User I/O} /system_tb/board/oled_vdd
add wave -noupdate -group {User I/O} /system_tb/board/ac_adc_sdata
add wave -noupdate -group {User I/O} /system_tb/board/ac_bclk
add wave -noupdate -group {User I/O} /system_tb/board/ac_lrclk
add wave -noupdate -group {User I/O} /system_tb/board/ac_mclk
add wave -noupdate -group {User I/O} /system_tb/board/ac_dac_sdata
add wave -noupdate -group {User I/O} /system_tb/board/sd_sck
add wave -noupdate -group {User I/O} /system_tb/board/sd_mosi
add wave -noupdate -group {User I/O} /system_tb/board/sd_cs
add wave -noupdate -group {User I/O} /system_tb/board/sd_reset
add wave -noupdate -group {User I/O} /system_tb/board/sd_cd
add wave -noupdate -group {User I/O} /system_tb/board/sd_miso
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_clk_n
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_clk_p
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_n
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_p
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_cec
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_scl
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_sda
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_hpa
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_rx_txen
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_tx_clk_n
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_tx_clk_p
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_tx_n
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_tx_p
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_tx_cec
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_tx_rscl
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_tx_rsda
add wave -noupdate -group {User I/O} /system_tb/board/hdmi_tx_hpd
add wave -noupdate -group {User I/O} /system_tb/board/eth_rxd
add wave -noupdate -group {User I/O} /system_tb/board/eth_rxctl
add wave -noupdate -group {User I/O} /system_tb/board/eth_rxck
add wave -noupdate -group {User I/O} /system_tb/board/eth_txd
add wave -noupdate -group {User I/O} /system_tb/board/eth_txctl
add wave -noupdate -group {User I/O} /system_tb/board/eth_txck
add wave -noupdate -group {User I/O} /system_tb/board/eth_mdio
add wave -noupdate -group {User I/O} /system_tb/board/eth_mdc
add wave -noupdate -group {User I/O} /system_tb/board/eth_int_b
add wave -noupdate -group {User I/O} /system_tb/board/eth_pme_b
add wave -noupdate -group {User I/O} /system_tb/board/eth_rst_b
add wave -noupdate /system_tb/board/led_o
add wave -noupdate -divider {Clock & Reset}
add wave -noupdate /system_tb/board/DUT/sys_clk
add wave -noupdate /system_tb/board/DUT/dbg_rst_n
add wave -noupdate /system_tb/board/DUT/sys_rst_n
add wave -noupdate -divider CPU
add wave -noupdate -group {CPU Registers} -label {ra (x1)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[1]}
add wave -noupdate -group {CPU Registers} -label {sp (x2)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[2]}
add wave -noupdate -group {CPU Registers} -label {gp (x3)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[3]}
add wave -noupdate -group {CPU Registers} -label {tp (x4)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[4]}
add wave -noupdate -group {CPU Registers} -label {t0 (x5)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[5]}
add wave -noupdate -group {CPU Registers} -label {t1 (x6)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[6]}
add wave -noupdate -group {CPU Registers} -label {t2 (x7)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[7]}
add wave -noupdate -group {CPU Registers} -label {s0 (x8)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[8]}
add wave -noupdate -group {CPU Registers} -label {s1 (x9)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[9]}
add wave -noupdate -group {CPU Registers} -label {a0 (x10)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[10]}
add wave -noupdate -group {CPU Registers} -label {a1 (x11)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[11]}
add wave -noupdate -group {CPU Registers} -label {a2 (x12)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[12]}
add wave -noupdate -group {CPU Registers} -label {a3 (x13)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[13]}
add wave -noupdate -group {CPU Registers} -label {a4 (x14)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[14]}
add wave -noupdate -group {CPU Registers} -label {a5 (x15)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[15]}
add wave -noupdate -group {CPU Registers} -label {a6 (x16)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[16]}
add wave -noupdate -group {CPU Registers} -label {a7 (x17)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[17]}
add wave -noupdate -group {CPU Registers} -label {s2 (x18)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[18]}
add wave -noupdate -group {CPU Registers} -label {s3 (x19)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[19]}
add wave -noupdate -group {CPU Registers} -label {s4 (x20)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[20]}
add wave -noupdate -group {CPU Registers} -label {s5 (x21)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[21]}
add wave -noupdate -group {CPU Registers} -label {s6 (x22)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[22]}
add wave -noupdate -group {CPU Registers} -label {s7 (x23)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[23]}
add wave -noupdate -group {CPU Registers} -label {s8 (x24)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[24]}
add wave -noupdate -group {CPU Registers} -label {s9 (x25)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[25]}
add wave -noupdate -group {CPU Registers} -label {s10 (x26)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[26]}
add wave -noupdate -group {CPU Registers} -label {s11 (x27)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[27]}
add wave -noupdate -group {CPU Registers} -label {t3 (x28)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[28]}
add wave -noupdate -group {CPU Registers} -label {t4 (x29)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[29]}
add wave -noupdate -group {CPU Registers} -label {t5 (x30)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[30]}
add wave -noupdate -group {CPU Registers} -label {t6 (x31)} {/system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/registers_i/mem[31]}
add wave -noupdate /system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/pc_id_i
add wave -noupdate /system_tb/board/DUT/core_i/cpu_i/u_core_default/id_stage_i/instr_ret_o
add wave -noupdate -divider TL-UL
add wave -noupdate /system_tb/board/DUT/core_i/tl_cpui_h2d
add wave -noupdate /system_tb/board/DUT/core_i/tl_cpui_d2h
add wave -noupdate /system_tb/board/DUT/core_i/tl_cpud_h2d
add wave -noupdate /system_tb/board/DUT/core_i/tl_cpud_d2h
add wave -noupdate /system_tb/board/DUT/core_i/tl_bram_main_h2d
add wave -noupdate /system_tb/board/DUT/core_i/tl_bram_main_d2h
add wave -noupdate -divider {Running Light}
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/led_o
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/reg_addr
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/reg_we
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/reg_re
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/reg_wdata
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/reg_rdata
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/pattern
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/mode
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/prescaler
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/prescaler_counter
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/prescaler_strobe
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/shift_amount
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/shift_direction
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/rotate
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/state
add wave -noupdate /system_tb/board/DUT/core_i/student_i/rlight_i/next
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {40160000000 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 421
configure wave -valuecolwidth 288
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 fs} {160734 ns}
