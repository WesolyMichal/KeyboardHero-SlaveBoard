import game_pkg::*;

module song_player(
    input logic clk,
    input logic rst_n,

    input logic [1:0] song_select,

    input logic enable_in,
    input logic tick,

    output logic final_note,

    output logic enable_out,
    output logic [15:0] timer,
    output note_t note_out [0:2],

    vga_if.in vga_in,
    vga_if.out vga_out
);

wire logic [1:0] song_select_del;
wire logic enable_ctl, enable_ctl_del;
wire logic tick_ctl, tick_ctl_del;
wire logic [15:0] timer_ctl, timer_ctl_del;
logic [7:0] note_addr;
note_t note [0:2];

delay #(
    .CLK_DEL(1),
    .WIDTH(2)
)sel_del(
    .clk,
    .rst_n,
    .din(song_select),
    .dout(song_select_del)
);

song_player_ctl ctl(
    .clk,
    .rst_n,
    .tick_in(tick),
    .enable_in,
    .enable_out(enable_ctl),
    .coming_note(note),
    .final_note,
    .note_addr,
    .tick_out(tick_ctl),
    .timer(timer_ctl)
);

song_rom rom(
    .clk,
    .note,
    .note_addr,
    .song_select(song_select_del)
);

delay #(
    .CLK_DEL(1),
    .WIDTH(18)
) mid_del(
    .clk,
    .rst_n,
    .din({enable_ctl, tick_ctl, timer_ctl}),
    .dout({enable_ctl_del, tick_ctl_del, timer_ctl_del})
);

song_player_out out(
    .clk,
    .rst_n,
    .enable_in(enable_ctl_del),
    .enable_out,
    .final_note,
    .note_in(note),
    .note_out,
    .tick_in(tick_ctl_del),
    .timer_in(timer_ctl_del),
    .timer_out(timer)
);

delay #(
    .CLK_DEL(3),
    .WIDTH(38)
)vga_delay(
    .clk,
    .rst_n,
    .din(vga_in),
    .dout(vga_out)
);

endmodule