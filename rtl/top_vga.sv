import game_pkg::*;

module top_vga (
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
    wire logic game_enable;
    wire game_if game_engine;
    wire logic [1:0] song_select; 

    // VGA signals from timing


    // VGA signals from background


    // VGA interfaces
    

    /**
     * Signals assignments
     */


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
        .game_enable,
        .game_engine,
        .song_choosing,
        .song_confirm,
        .song_select
    );



endmodule
