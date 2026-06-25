import game_pkg::*;

module song_mask4test (
    input logic clk,
    input logic rst_n,

    input logic enable_mask_in,
    input logic [1:0] song_select, // Input to select the song from ROM
    input logic [15:0] timer,
    input logic [7:0] note_addr,

    vga_if.in vga_in,
    vga_if.out vga_out
);

wire logic [37:0] vga_player, vga_fill;

wire logic enable_note_fill, enable_outlogic;
wire logic note_fill[0:5][0:639];

note_t note_player [0:2];

delay #(
    .CLK_DEL(1),
    .WIDTH(38)
)vga_delay(
    .clk,
    .rst_n,
    .din(vga_in),
    .dout(vga_player)
);

delay #(
    .CLK_DEL(1),
    .WIDTH(1)
)enable_delay(
    .clk,
    .rst_n,
    .din(enable_mask_in),
    .dout(enable_note_fill)
);

song_rom rom(
    .clk,
    .note(note_player),
    .note_addr,
    .song_select
);

note_fill_ctl u_note_fill(
    .clk,
    .rst_n,
    .current_note(note_player),
    .enable_in(enable_note_fill),
    .enable_out(enable_outlogic),
    .note_fill,
    .timer,
    .vga_in(vga_player),
    .vga_out(vga_fill)
);

song_out_logic u_song_mask_out(
    .clk,
    .rst_n,
    .enable_in(enable_outlogic),
    .note_fill,
    .vga_in(vga_fill),
    .vga_out
);

endmodule
