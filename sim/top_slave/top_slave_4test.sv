import game_pkg::*;
import vga_pkg::*;

module top_slave_4test (
        input  logic clk,
        input  logic rst_n,
        input logic read_data,
        input logic [7:0] r_data,
        output vga_if vga_out
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */

    wire logic enter, esc, song_choosing, song_confirm;
    wire logic enable_song_mask;
    wire game_if game_engine, game_engine_del;
    wire logic [1:0] song_select, master_song, master_song_del; 

    wire enable_bgs enable_bgs_FSM;

    wire final_note, enter_out;
    wire [15:0] end_score;

    // VGA interfaces
    vga_if vga_bg;

    /**
     * Submodules instances
     */

    comm_decoder u_comm_decoder(
        .clk,
        .rst_n,
        .read_data,
        .r_data,
        .enter,
        .esc,
        .game_enable(enable_bgs_FSM.enable_song),
        .game_engine,
        .song_choosing,
        .song_confirm,
        .song_select
    );

    slave_FSM u_slave_FSM(
        .clk,
        .rst_n,
        .enter,
        .esc,
        .song_confirm,
        .master_song_select(song_select),
        .enable_bgs_FSM,
        .enter_out_FSM(enter_out),
        .final_note,
        .master_song,
        .status(game_engine.status)
    );

    top_bg u_top_bg(
        .clk,
        .rst_n,
        .enable_backgrounds(enable_bgs_FSM),
        .enable_song(enable_song_mask),
        .enter_in_FSM(enter_out),
        .master_song,
        .score_in(end_score),
        .vga_out(vga_bg)
    );

    delay #(
        .CLK_DEL(5),
        .WIDTH(8)
    )  u_delay_game (
        .clk,
        .rst_n,
        .din(game_engine),
        .dout(game_engine_del)
    );

    delay #(
        .CLK_DEL(4),
        .WIDTH(2)
    )  u_delay_select (
        .clk,
        .rst_n,
        .din(master_song),
        .dout(master_song_del)
    );

    song_mask #(
        .TICK_FREQUENCY(1_000_000)
    )u_song_mask(
        .clk,
        .rst_n,
        .vga_in(vga_bg),
        .vga_out,
        .final_note,
        .end_score,
        .song_select(master_song_del),
        .game_engine(game_engine_del),
        .enable_in(enable_song_mask)
    );

endmodule
