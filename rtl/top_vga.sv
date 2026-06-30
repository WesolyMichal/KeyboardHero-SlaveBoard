import game_pkg::*;

module top_vga (
        input  logic clk,
        input  logic rst_n,
        input logic [7:0] UART_in,
        output logic vs,
        output logic hs,
        output logic [3:0] r,
        output logic [3:0] g,
        output logic [3:0] b
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */
    wire [7:0] button;
    wire enable_start, enable_song_choose, enable_song, enable_endscreen;
   // wire [7:0] UART_in;
    wire enable_song_mux;

    // VGA signals from timing
    wire vga_if vga_tim;

    // VGA signals from background
    wire vga_if vga_bg;

    // VGA interfaces
    vga_if vga_out_timing_if();
    vga_if vga_out_top_bg_if();

    /**
     * Signals assignments
     */

    assign vs = vga_bg.vsync;
    assign hs = vga_bg.hsync;
    assign {r,g,b} = vga_bg.rgb;


    /**
     * Submodules instances
     */

    slave_FSM u_slave_fsm (
        .clk,
        .rst_n,
        .UART_in(UART_in),
        .button(button),
        .master_song(),
        .enable_start,
        .enable_song_choose,
        .enable_song,
        .enable_endscreen
    );

    vga_timing u_vga_timing (
        .clk,
        .rst_n,
        .vga_out(vga_tim)
    );

    top_bg u_top_bg (
        .clk,
        .rst_n,
        .button(button),
        .score_in(),
        .enable_start(enable_start),
        .enable_song_choose(enable_song_choose),
        .enable_song(enable_song),
        .enable_endscreen(enable_endscreen),
        .vga_in(vga_out_timing_if),
        .enable_song_mux(enable_song_mux),
        .vga_out(vga_out_top_bg_if)
    );

endmodule
