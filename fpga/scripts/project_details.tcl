# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# Project detiles required for generate_bitstream.tcl
# Make sure that project_name, top_module and target are correct.
# Provide paths to all the files required for synthesis and implementation.
# Depending on the file type, it should be added in the corresponding section.
# If the project does not use files of some type, leave the corresponding section commented out.

#-----------------------------------------------------#
#                   Project details                   #
#-----------------------------------------------------#
# Project name                                  -- EDIT
set project_name vga_project

# Top module name                               -- EDIT
set top_module top_vga_basys3

# FPGA device
set target xc7a35tcpg236-1

#-----------------------------------------------------#
#                    Design sources                   #
#-----------------------------------------------------#
# Specify .xdc files location                   -- EDIT
set xdc_files {
    constraints/top_vga_basys3.xdc
}

# Specify SystemVerilog design files location   -- EDIT
set sv_files {
    ../rtl/BG/endscreen_bg.sv
    ../rtl/BG/mux_bg.sv
    ../rtl/BG/song_bg.sv
    ../rtl/BG/song_choose_bg.sv
    ../rtl/BG/start_bg.sv
    ../rtl/top_bg.sv
    ../rtl/rom/agh_image_rom.sv
    ../rtl/rom/enter_button_rom.sv
    ../rtl/rom/font_rom.sv
    ../rtl/rom/mibombo_rom.sv
    ../rtl/rom/song_rom.sv
    ../rtl/rom/star_rom.sv
    ../rtl/song_mask/song_player/song_player.sv
    ../rtl/song_mask/song_player/song_player_ctl.sv
    ../rtl/song_mask/song_player/song_player_out.sv
    ../rtl/song_mask/button_mask.sv
    ../rtl/song_mask/note_fill_ctl.sv
    ../rtl/song_mask/score_counter.sv
    ../rtl/song_mask/score_mask.sv
    ../rtl/song_mask/song_mask_pkg.sv
    ../rtl/song_mask/song_mask.sv
    ../rtl/song_mask/timer.sv
    ../rtl/uart/uart_reader.sv
    ../rtl/comm_decoder.sv
    ../rtl/delay.sv
    ../rtl/game_pkg.sv
    ../rtl/slave_FSM.sv
    ../rtl/top_bg.sv
    ../rtl/top_slave.sv
    ../rtl/vga_pkg.sv
    ../rtl/vga_timing.sv
    ../rtl/bg_testing.sv
    rtl/top_vga_basys3.sv
}

# Specify Verilog design files location         -- EDIT
set verilog_files {
    ../rtl/uart/debounce.v
    ../rtl/uart/disp_hex_mux.v
    ../rtl/uart/fifo.v
    ../rtl/uart/flag_buf.v
    ../rtl/uart/mod_m_counter.v
    ../rtl/uart/uart_rx.v
    ../rtl/uart/uart_tx.v
    ../rtl/uart/uart.v
}

# Specify VHDL design files location            -- EDIT
# set vhdl_files {
#    path/to/file.vhd
# }

# Specify files for a memory initialization     -- EDIT
set mem_files {
   ../rtl/data/agh_image_rom.data
   ../rtl/data/enter.data
   ../rtl/data/mibombo_color.data
   ../rtl/data/mibombo.data
   ../rtl/data/star.data
   ../rtl/songs/song_0.data
   ../rtl/songs/song_1.data
   ../rtl/songs/song_2.data
   ../rtl/songs/song_3.data
}
