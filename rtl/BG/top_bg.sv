import vga_pkg::*;
import game_pkg::*;

module top_bg (
    input logic clk,
    input logic rst_n,

    input enter_in_FSM,
    input [1:0] master_song,
    input logic [15:0] score_in,
    input game_pkg::enable_bgs enable_backgrounds, 

    input vga_if vga_in,
    output vga_if vga_out,
    output logic enable_song
);

game_pkg::enable_bgs enable_from_bg;
wire [11:0] rgb_out_start_bg, rgb_out_choose_bg, rgb_out_song_bg, rgb_out_endscreen_bg; 

vga_if delay_vga_out; 

start_bg u_start_bg (
    .clk,
    .rst_n,
    .enter(enter_in_FSM),
    .enable_start_in(enable_backgrounds.enable_start),
    .vga_in(vga_in),
    .enable_start_out(enable_from_bg.enable_start),
    .rgb_out_start_bg
);

song_choose_bg u_song_choose_bg (
    .clk,
    .rst_n,
    .vga_in(vga_in),
    .master_song(master_song),
    .enable_choose_in(enable_backgrounds.enable_song_choose),
    .enable_choose_out(enable_from_bg.enable_song_choose),
    .rgb_out_choose_bg
);

song_bg u_song_bg (
    .clk,
    .rst_n,
    .enable_song_in(enable_backgrounds.enable_song),
    .vga_in(vga_in),
    .enable_song_out(enable_from_bg.enable_song),
    .rgb_out_song_bg
);

endscreen_bg u_endscreen_bg(
    .clk,
    .rst_n,
    .end_score_in(score_in),
    .enable_endscreen_in(enable_backgrounds.enable_endscreen),
    .vga_in(vga_in),
    .enable_endscreen_out(enable_from_bg.enable_endscreen),
    .rgb_out_endscreen_bg
);

delay #(
    .CLK_DEL(3),
    .WIDTH(38)
) u_delay_vga(
    .clk,
    .rst_n,
    .din(vga_in),
    .dout(delay_vga_out)
);

mux_bg u_mux_bg (
    .clk,
    .rst_n,
    .enable_from_bg,
    .rgb_start(rgb_out_start_bg),
    .rgb_choose(rgb_out_choose_bg),
    .rgb_song(rgb_out_song_bg),
    .rgb_endscreen(rgb_out_endscreen_bg),
    .delay_vga_in(delay_vga_out),
    .enable_song_out(enable_song),
    .vga_out(vga_out)
);

endmodule