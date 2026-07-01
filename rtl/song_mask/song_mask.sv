import game_pkg::*;

module song_mask #(
    parameter TICK_FREQUENCY = 1000
)(
    input logic clk,
    input logic rst_n,

    input game_if game_engine,

    input logic enable_in,
    input logic [1:0] song_select, // Input to select the song from ROM

    input vga_if vga_in,
    output vga_if vga_out,

    output logic final_note,

    output logic [15:0] end_score
);

vga_if vga_del, vga_player, vga_fill, vga_score;

wire logic tick;
wire logic enable_note_fill, enable_player, enable_score, enable_buttons;

wire logic [31:0] timer_n;

note_t note_player [0:2];

wire logic [1:0] song_select_del;

wire logic [15:0] current_score;
wire logic [3:0]  current_multiplier;

game_action status_del;
wire logic [5:0] buttons_del;

wire logic enable_out;

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
    .enable(enable_in),
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
    .enable_out(enable_score),
    .timer(timer_n),
    .vga_in(vga_player),
    .vga_out(vga_fill)
);

delay #(
    .CLK_DEL(3),
    .WIDTH(2)
) u_delay_status (
    .clk,
    .rst_n,
    .din(game_engine.status),
    .dout({status_del})
);

score_counter u_score_counter(
    .clk,
    .rst_n,
    .current_multiplier,
    .current_score,
    .end_score,
    .game_active(enable_note_fill),
    .player_action(status_del),
    .action_strobe(tick) // trzeba zmienic zeby dodawalo co tick gdy trzymamy dlugo
);

score_mask u_score_mask(
    .clk,
    .rst_n,
    .vga_in(vga_fill),
    .vga_out(vga_score),
    .current_multiplier,
    .current_score,
    .enable_in(enable_score),
    .enable_out(enable_buttons)
);

delay #(
    .CLK_DEL(4),
    .WIDTH(6)
) u_delay_buttons (
    .clk,
    .rst_n,
    .din(game_engine.buttons),
    .dout(buttons_del)
);

button_mask u_button_mask(
    .clk,
    .rst_n,
    .enable_in(enable_buttons),
    .buttons(buttons_del),
    .vga_in(vga_score),
    .vga_out
);

endmodule
