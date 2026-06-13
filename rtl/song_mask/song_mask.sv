import game_pkg::*;

module song_mask (
    input logic clk,
    input logic rst_n,

    input logic enable_mask_in,
    input logic [1:0] song_select, // Input to select the song from ROM

    vga_if.in vga_in,
    vga_if.out vga_out,

    output logic final_note
);

wire logic tick;
wire logic enable_note_fill, enable_player, enable_outlogic;
wire logic note_fill[0:5][0:639];

logic [15:0] timer;
logic [7:0] note_addr;
note_t current_note[0:2], cur_note_del4fill;
vga_if vga_del4outlogic;

timer u_ticker(
    .clk,
    .rst_n,
    .enable(enable_mask_in),
    .tick,
    .enable_out(enable_player)
);

song_rom u_song_rom(
    .clk,
    .song_select,
    .note_addr,
    .note(current_note)
);

song_player u_song_player(
    .clk,
    .rst_n,
    .enable_in(enable_player),
    .enable_out(enable_note_fill),
    .current_note(current_note[0]),
    .note_addr,
    .tick,
    .timer,
    .final_note
);

delay #(
    .CLK_DEL(1),
    .WIDTH(3*48)
)u_delay_note(
    .clk,
    .rst_n,
    .din(current_note),
    .dout(cur_note_del4fill)
);

delay #(
    .CLK_DEL(3), //to koniecznie trzeba zweryfikować,
    .WIDTH(38)
)u_delay_vga(
    .clk,
    .rst_n,
    .din(vga_in),
    .dout(vga_del4outlogic)
);

note_fill_ctl u_note_fill(
    .clk,
    .rst_n,
    .current_note(cur_note_del4fill),
    .enable_in(enable_note_fill),
    .enable_out(enable_outlogic),
    .note_fill,
    .timer
);

song_out_logic u_song_mask_out(
    .clk,
    .rst_n,
    .enable_in(enable_outlogic),
    .note_fill,
    .vga_in(vga_del4outlogic),
    .vga_out
);

endmodule
