import game_pkg::*;

module song_player_ctl(
    input logic clk,
    input logic rst_n,

    input logic enable_in,
    input logic tick_in,
    output logic tick_out,

    input logic final_note,
    input note_t coming_note[0:2],
    
    output logic [7:0] note_addr,
    output logic enable_out,
    output logic [31:0] timer
);

logic enable_out_nxt, enable_last;
logic [31:0] timer_nxt;
logic [7:0] note_addr_nxt;
note_t current_note, current_note_nxt;

enum logic {IDLE, PLAYING} state, state_nxt;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state      <= IDLE;
        enable_out <= '0;
        enable_last<= '0;
        timer      <= '0;
        note_addr  <= '0;
        current_note <= '0;
        tick_out   <= '0;
    end else begin
        state      <= state_nxt;
        enable_out <= enable_out_nxt;
        enable_last<= enable_in;
        timer      <= timer_nxt;
        note_addr  <= note_addr_nxt;
        current_note <= current_note_nxt;
        tick_out   <= tick_in;
    end
end

always_comb begin: state_blk
    state_nxt = state;

    case(state)
        IDLE: state_nxt = (enable_in && (!enable_last)) ? PLAYING : IDLE;
        PLAYING: begin
            if(enable_in) begin
                if(tick_in) begin
                    if(final_note)
                        state_nxt = IDLE;
                    else state_nxt = PLAYING;
                end
            end else state_nxt = IDLE;
        end
    endcase
end: state_blk

always_comb begin: enable_out_blk
    enable_out_nxt = enable_out;

    if(enable_in) begin
        enable_out_nxt = (state == PLAYING) ? '1 : '0;
    end else enable_out_nxt = '0;

end: enable_out_blk

always_comb begin: timer_blk
    timer_nxt = timer;

    if(enable_in) begin
        case(state)
            IDLE: timer_nxt = '0;
            PLAYING: begin
                if(tick_in) begin
                    if(timer >= (current_note.duration + current_note.waiting - 1))
                        timer_nxt = '0;
                    else
                        timer_nxt = timer + 1;
                end
            end
        endcase
    end else timer_nxt = '0;

end: timer_blk

always_comb begin: note_addr_blk
    note_addr_nxt = note_addr;

    if(enable_in) begin
        case(state)
            IDLE: note_addr_nxt = '0;
            PLAYING: begin
                if(tick_in) begin
                    if(timer == (current_note.duration + current_note.waiting - 1))
                        note_addr_nxt = note_addr + 1;
                end
            end
        endcase
    end else note_addr_nxt = '0;

end: note_addr_blk

always_comb begin: note_blk
    current_note_nxt = current_note_nxt;

    if(enable_in) begin
        case(state)
            IDLE: current_note_nxt = coming_note[0];
            PLAYING: begin
                if(tick_in) begin
                    if(timer >= (current_note.duration + current_note.waiting - 1))
                        current_note_nxt = coming_note[1];
                    else
                        current_note_nxt = current_note;
                end
            end
        endcase
    end else current_note_nxt = '0;

end: note_blk

endmodule