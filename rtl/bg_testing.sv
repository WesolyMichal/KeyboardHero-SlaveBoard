import vga_pkg::*;
import game_pkg::*;

module bg_testing(
    input  logic clk,
    input  logic rst_n,
    output logic vs,
    output logic hs,
    output logic [3:0] r,
    output logic [3:0] g,
    output logic [3:0] b
);

vga_if vga_tim, vga_out;

logic [11:0] rgb_out;
logic enable_out;

vga_timing u_timing(
    .clk,
    .rst_n,
    .vga_out(vga_tim)
);

// start_bg u_start (
//     .clk,
//     .rst_n,
//     .enter(1'b1),
//     .enable_start_in(1'b1),
//     .vga_in(vga_tim),
//     .enable_start_out(enable_out),
//     .rgb_out_start_bg(rgb_out)
// );

// song_choose_bg u_song_choose (
//     .clk,
//     .rst_n,
//     .enable_choose_in(1'b1),
//     .enable_choose_out(enable_out),
//     .master_song(2'b1),
//     .rgb_out_choose_bg(rgb_out),
//     .vga_in(vga_tim)
// );

endscreen_bg u_endscreen(
    .clk,
    .rst_n,
    .enable_endscreen_in(1'b1),
    .enable_endscreen_out(enable_out),
    .end_score_in(16'h1234),
    .rgb_out_endscreen_bg(rgb_out),
    .vga_in(vga_tim)
);

delay #(
    .CLK_DEL(3),
    .WIDTH(38)
) u_delay_vga(
    .clk,
    .rst_n,
    .din(vga_tim),
    .dout(vga_out)
);

assign vs = vga_out.vsync;
assign hs = vga_out.hsync;
assign {r, g, b} = rgb_out;

endmodule