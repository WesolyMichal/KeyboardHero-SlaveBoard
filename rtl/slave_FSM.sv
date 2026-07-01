import game_pkg::*;

module slave_FSM (
    input logic clk,
    input logic rst_n,
    input logic final_note,

    input logic song_confirm,
    input logic [1:0] master_song_select,

    input logic enter,
    input logic esc,
    input game_action status,

    output logic [1:0] master_song,
    output game_pkg::enable_bgs enable_bgs_FSM,
    output logic enter_out_FSM
);

enum logic [2:0] {INIT, WAIT_CONN, HOME_SCREEN, WAIT_HOMESCREEN, SONG_CHOOSE, PLAY_SONG, ENDSCREEN} state, state_nxt;

logic [3:0] timer, timer_nxt;
logic [1:0] master_song_nxt;

always_ff @(posedge clk) begin
    if(!rst_n) begin
        state <= INIT;
        timer <= '0;
        master_song <= '0;
    end else begin
        state <= state_nxt;
        timer <= timer_nxt;
        master_song <= master_song_nxt;
    end
end

always_comb begin //obsuga stanow
    master_song_nxt = master_song;
    state_nxt = state;

    case (state)
        INIT: state_nxt = WAIT_CONN;
        WAIT_CONN:      if (enter) begin
                            state_nxt = HOME_SCREEN;
                        end else begin
                            state_nxt = WAIT_CONN;
                        end
        HOME_SCREEN:    if (enter) begin
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
        SONG_CHOOSE:    if(song_confirm) begin
                            master_song_nxt = master_song_select;
                            state_nxt = PLAY_SONG;
                        end else if(esc) begin
                            master_song_nxt = '0;
                            state_nxt = HOME_SCREEN;
                        end else begin
                            master_song_nxt = master_song_select;
                            state_nxt = SONG_CHOOSE;
                        end
        PLAY_SONG:      if (status == END_GAME || final_note) begin
                            state_nxt = ENDSCREEN;
                        end else if (esc) begin
                            state_nxt = SONG_CHOOSE;
                            master_song_nxt = '0;
                        end else begin 
                            state_nxt = PLAY_SONG;
                        end
        ENDSCREEN:      if (esc) begin
                            state_nxt = SONG_CHOOSE;
                            master_song_nxt = '0;
                        end else begin 
                            state_nxt = ENDSCREEN;
                        end             
    endcase
end

always_comb begin //obsuga wyjsc
    enable_bgs_FSM.enable_start = (state == (HOME_SCREEN || WAIT_HOMESCREEN));
    enable_bgs_FSM.enable_song_choose = (state == SONG_CHOOSE);
    enable_bgs_FSM.enable_song = (state == PLAY_SONG);
    enable_bgs_FSM.enable_endscreen = (state == ENDSCREEN);
    
    enter_out_FSM = (state == WAIT_HOMESCREEN);
end

endmodule