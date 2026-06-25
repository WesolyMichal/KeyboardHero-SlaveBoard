import game_pkg::*;

module song_player_out(
    input logic clk,
    input logic rst_n,
    input logic tick_in,

    input note_t note_in [0:2],
    output note_t note_out [0:2],

    input logic enable_in,
    output logic enable_out,
    
    input logic [15:0] timer_in,
    output logic [15:0] timer_out,

    output logic final_note
);

logic final_note_nxt;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        final_note <= '0;
        note_out <= '{'0, '0, '0};
        enable_out <= '0;
        timer_out <= '0;
    end else begin
        final_note <= final_note_nxt;
        note_out <= note_in;
        enable_out <= enable_in;
        timer_out <= timer_in;
    end
end

always_comb begin: final_note_blk
    final_note_nxt = '0;

    if(enable_in) begin
        if(tick_in) begin
            if((note_in[0].data == 4'hf) && timer_in >= note_in[0].waiting + note_in[0].duration - 1)
            final_note_nxt = '1;
            else final_note_nxt = '0;
        end
    end else final_note_nxt = '0;

end: final_note_blk

endmodule