import game_pkg::*;

module song_player(
    input logic clk,
    input logic rst_n,

    input logic enable_in,
    input logic tick,

    input note_t current_note,

    output logic final_note,

    output logic [7:0] note_addr,
    output logic enable_out,
    output logic [15:0] timer
);

logic [7:0] note_addr_nxt;
logic enable_out_nxt, enable_last, final_note_nxt;
logic [15:0] timer_nxt;

enum logic {IDLE, PLAYING} state, state_nxt;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state      <= IDLE;
        note_addr  <= '0;
        enable_out <= '0;
        enable_last<= '0;
        timer      <= '0;
        final_note <= '0;
    end else begin
        state      <= state_nxt;
        note_addr  <= note_addr_nxt;
        enable_out <= enable_out_nxt;
        enable_last<= enable_in;
        timer      <= timer_nxt;
        final_note <= final_note_nxt;
    end
end

always_comb begin: state_blk
    state_nxt = state;

    case(state)
        IDLE: state_nxt = (enable_in && (!enable_last)) ? PLAYING : IDLE;
        PLAYING: begin
            if(enable_in) begin
                if(tick) begin
                    if((current_note.data == 4'hf) && timer >= current_note.waiting + current_note.duration - 1)
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
                if(tick) begin
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
                if(tick) begin
                    if(timer >= (current_note.duration + current_note.waiting - 1))
                        note_addr_nxt = note_addr + 1;
                end
            end
        endcase
    end else note_addr_nxt = '0;

end: note_addr_blk

always_comb begin: final_note_blk
    final_note_nxt = '0;

    case(state)
        IDLE: final_note_nxt = '0;
        PLAYING: begin
            if(enable_in) begin
                if(tick) begin
                    if((current_note.data == 4'hf) && timer >= current_note.waiting + current_note.duration - 1)
                    final_note_nxt = '1;
                    else final_note_nxt = '0;
                end
            end else final_note_nxt = '0;;
        end
    endcase

end: final_note_blk

endmodule