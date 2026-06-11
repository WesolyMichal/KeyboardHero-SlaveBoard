module top_bg (
    input logic clk,
    input logic rst_n,

    input [7:0] button,
    input logic [15:0] score_in,
    input logic enable_start,
    input logic enable_song_choose,
    input logic enable_song,
    input logic enable_endscreen,

    vga_if.in_bez_rgb vga_in,
    vga_if.out vga_out
);

import vga_pkg::*;

wire enable_start_out, enable_choose_out, enable_song_out, enable_endscreen_out;
wire [11:0] rgb_out_start_bg, rgb_out_choose_bg, rgb_out_song_bg, rgb_out_endscreen_bg; 

vga_if delay_vga_out (); 

start_bg u_start_bg (
    .clk,
    .rst_n,
    .button,
    .enable_start_in(enable_start),
    .vga_in(vga_in),
    .enable_start_out,
    .rgb_out_start_bg
);

song_choose_bg u_song_choose_bg (
    .clk,
    .rst_n,
    .vga_in(vga_in),
    .button,
    .enable_choose_in(enable_song_choose),
    .enable_choose_out,
    .rgb_out_choose_bg,
    .selected_song()
);

song_bg u_song_bg (
    .clk,
    .rst_n,
    .enable_song_in(enable_song),
    .vga_in(vga_in),
    .enable_song_out,
    .rgb_out_song_bg
);

endscreen_bg u_endscreen_bg(
    .clk,
    .rst_n,
    .end_score_in(score_in),
    .enable_endscreen_in(enable_endscreen),
    .vga_in(vga_in),
    .enable_endscreen_out,
    .rgb_out_endscreen_bg
);

delay_vga_if u_delay_vga_if(
    .clk,
    .rst_n,
    .vga_in(vga_in),
    .delay_vga_out(delay_vga_out)
);

mux_bg u_mux_bg (
    .clk,
    .rst_n,
    .enable_start(enable_start_out),
    .rgb_start(rgb_out_start_bg),
    .enable_song_choose(enable_choose_out),
    .rgb_choose(rgb_out_choose_bg),
    .enable_song(enable_song_out),
    .rgb_song(rgb_out_song_bg),
    .enable_endscreen(enable_endscreen_out),
    .rgb_endscreen(rgb_out_endscreen_bg),
    .delay_vga_in(delay_vga_out),
    .vga_out(vga_out)
);

endmodule