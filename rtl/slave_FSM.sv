module slave_FSM (
    input logic clk,
    input logic rst_n,

    input logic [7:0] UART_in,

    output logic [7:0] button,
    output logic [1:0] state_out,
    output logic enable_song
);

enum logic [2:0] {INIT, WAIT_CONN, IDLE, HOME_SCREEN, CHOOSE_SONG, PLAY_SONG, END_SCREEN} state, state_nxt;

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
    end else begin
        state <= state_nxt;
    end
end




endmodule