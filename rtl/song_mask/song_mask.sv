import game_pkg::*;

module song_mask #(
    parameter TICK_FREQUENCY = 1000
)(
    input logic clk,
    input logic rst_n,

    input logic enable_mask_in,
    input logic [1:0] song_select, // Input to select the song from ROM

    input vga_if vga_in,
    output vga_if vga_out,

    output logic final_note
);

wire logic [37:0] vga_del, vga_player, vga_fill;

wire logic tick;
wire logic enable_note_fill, enable_player, enable_outlogic;
wire logic note_fill[0:5][0:639];

wire logic [31:0] timer_n;

note_t note_player [0:2];

wire logic [1:0] song_select_del;


delay #(
    .CLK_DEL(1),
    .WIDTH(38)
)vga_delay(
    .clk,
    .rst_n,
    .din(vga_in),
    .dout(vga_del)
);

delay #(
    .CLK_DEL(1),
    .WIDTH(2)
)select_delay(
    .clk,
    .rst_n,
    .din(song_select),
    .dout(song_select_del)
);

timer #(
    .FREQUENCY(TICK_FREQUENCY)
) u_ticker(
    .clk,
    .rst_n,
    .enable(enable_mask_in),
    .tick,
    .enable_out(enable_player)
);

song_player u_song_player(
    .clk,
    .rst_n,
    .song_select(song_select_del),
    .enable_in(enable_player),
    .enable_out(enable_note_fill),
    .final_note,
    .note_out(note_player),
    .tick,
    .timer(timer_n),
    .vga_in(vga_del),
    .vga_out(vga_player)
);

note_fill_ctl u_note_fill(
    .clk,
    .rst_n,
    .current_note(note_player),
    .enable_in(enable_note_fill),
    .enable_out(enable_outlogic),
    .timer(timer_n),
    .vga_in(vga_player),
    .vga_out
);


endmodule
