import game_pkg::*;

module slave_FSM (
    input logic clk,
    input logic rst_n,

    input logic [7:0] UART_in,

    output logic [7:0] button,
    output logic [1:0] master_song,

    output logic enable_start,
    output logic enable_song_choose,
    output logic enable_song,
    output logic enable_endscreen
);

enum logic [2:0] {INIT, WAIT_CONN, IDLE, HOME_SCREEN, WAIT_HOMESCREEN, SONG_CHOOSE, PLAY_SONG, ENDSCREEN} state, state_nxt;

logic [3:0] timer, timer_nxt;

logic [7:0] button_nxt;

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
        timer <= '0;
        button_nxt <= '0;
    end else begin
        state <= state_nxt;
        timer <= timer_nxt;
        button <= button_nxt;
    end
end

always_comb begin //obsuga stanow
    case (state)
        INIT: state_nxt = WAIT_CONN;
        WAIT_CONN:      if (UART_in == ENTER) begin
                            state_nxt = HOME_SCREEN;
                        end else begin
                            state_nxt = WAIT_CONN;
                        end
        HOME_SCREEN:    if (UART_in == ENTER) begin
                            state_nxt = WAIT_HOMESCREEN;
                            timer_nxt = 10;
                        end else begin 
                            state_nxt = HOME_SCREEN;
                        end
        WAIT_HOMESCREEN: if(timer_nxt == 0) begin
                            state_nxt = SONG_CHOOSE;
                        end else begin
                            state_nxt = WAIT_HOMESCREEN;
                            timer_nxt = timer - 1;
                        end
        SONG_CHOOSE:    if(UART_in[3:0] == CONFIRM) begin
                            master_song = UART_in[5:4];
                            state_nxt = PLAY_SONG;
                        end else if(UART_in == ESC) begin
                            state_nxt = HOME_SCREEN;
                        end else begin
                            state_nxt = SONG_CHOOSE;
                        end
        PLAY_SONG:      if (UART_in[7:6] == END_GAME) begin
                            state_nxt = ENDSCREEN;
                        end else if (UART_in == ESC) begin //
                            state_nxt = SONG_CHOOSE;
                        end else begin 
                            state_nxt = PLAY_SONG;
                        end
                        ENDSCREEN: if (UART_in == ENTER) begin
                        state_nxt = SONG_CHOOSE;
                    end else begin 
                        state_nxt = ENDSCREEN;
                    end             
    endcase
end

always_comb begin //obsuga wyjsc
    enable_start = (state == (HOME_SCREEN || WAIT_HOMESCREEN));
    enable_song_choose = (state ==SONG_CHOOSE);
    enable_song = (state == PLAY_SONG);
    enable_endscreen = (state == ENDSCREEN);

    button_nxt = (state == WAIT_HOMESCREEN)?  ENTER : UART_in;
end

endmodule