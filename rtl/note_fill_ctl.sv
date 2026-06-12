import game_pkg::*;

module note_fill_ctl #(
    parameter SCREEN_HEIGHT = 640,
    parameter SCALE = 0.5,
    parameter MINIMUM_HEIGHT = 10
)(
    input logic clk,
    input logic rst_n,
    input logic enable,
    
    input logic tick,
    input note_t current_note [0:2],

    output logic note_fill[0:5][0:SCREEN_HEIGHT-1]
);

logic note_fill_nxt[0:5][0:SCREEN_HEIGHT-1];
note_t current_note_last [0:2];

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        note_fill <= '{0, 0, 0, 0, 0, 0};
        current_note_last <= {0, 0, 0};
    end else begin
        note_fill <= note_fill_nxt;
        current_note_last <= current_note;
    end
end

always_comb begin
    note_fill_nxt = note_fill;

    if(!enable) begin
        note_fill_nxt = '{0, 0, 0, 0, 0, 0};
    end else begin

    end
end

endmodule