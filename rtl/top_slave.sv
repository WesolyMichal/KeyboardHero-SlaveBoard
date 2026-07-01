import game_pkg::*;
import vga_pkg::*;

module top_slave (
        input  logic clk,
        input  logic rst_n,
        input logic UART_rx,
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
    
    wire logic [7:0] MSG, r_data;
    wire logic rd_uart, rx_empty, read_data;

    wire logic enter, esc, song_choosing, song_confirm;
    wire logic enable_song_mask;
    wire game_if game_engine, game_engine_del;
    wire logic [1:0] song_select, master_song, master_song_del; 

    wire enable_bgs enable_bgs_FSM;

    wire final_note, enter_out;
    wire [15:0] end_score;

    // VGA interfaces
    vga_if vga_bg, vga_out;

    /**
     * Signals assignments
     */

    assign vs = vga_out.vsync;
    assign hs = vga_out.hsync;
    assign {r, g, b} = vga_out.rgb;

    /**
     * Submodules instances
     */

    uart #(
        .DVSR(36)
    )u_uart(
        .clk,
        .reset(!rst_n),
        .rx(UART_rx),
        .r_data,
        .rd_uart,
        .rx_empty
    );

    uart_reader u_uart_reader(
        .clk,
        .rst_n,
        .rx_empty,
        .rd_uart,
        .r_data,
        .data_ready(read_data),
        .out_data(MSG)
    );

    comm_decoder u_comm_decoder(
        .clk,
        .rst_n,
        .read_data,
        .r_data(MSG),
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
        .final_note,
        .enter_out_FSM(enter_out),
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

    song_mask u_song_mask(
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
