import game_pkg::*;

module note_fill_ctl #(
    parameter SCREEN_HEIGHT = 640,
    parameter INV_SCALE = 20,
    parameter MINIMUM_HEIGHT = 10
)(
    input logic clk,
    input logic rst_n,
    input logic enable,
    
    input logic [15:0] timer,
    input note_t current_note [0:2],

    output logic note_fill[0:5][0:SCREEN_HEIGHT-1]
);

logic note_fill_nxt[0:5][0:SCREEN_HEIGHT-1];

logic [15:0] waiting_remaining, duration_remaining;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        note_fill <= '{0, 0, 0, 0, 0, 0};
    end else begin
        note_fill <= note_fill_nxt;
    end
end

always_comb begin
    note_fill_nxt = note_fill;

    waiting_remaining = (timer < current_note[0].waiting) ? (current_note[0].waiting - timer) : 0;
    duration_remaining = (timer < current_note[0].waiting) ? current_note[0].duration : current_note[0].duration - (timer - current_note[0].waiting);

    if(!enable) begin
        note_fill_nxt = '{0, 0, 0, 0, 0, 0};
    end else begin
        for(logic [2:0] column = 0; column < 6; column++) begin
            for(logic [11:0] y_pixel; y_pixel < SCREEN_HEIGHT; y_pixel++) begin

                if(current_note[0].buttons[column]) begin

                    if((y_pixel * INV_SCALE >= waiting_remaining 
                                            - MINIMUM_HEIGHT)

                    && (y_pixel * INV_SCALE <  waiting_remaining 
                                            + MINIMUM_HEIGHT 
                                            + (current_note[0].long[column] ? duration_remaining : 0) ) ) 

                        note_fill_nxt[column][y_pixel] = 1'b1;

                end else if(current_note[1].buttons[column]) begin

                    if((y_pixel * INV_SCALE >= waiting_remaining 
                                            + duration_remaining 
                                            + current_note[1].waiting 
                                            - MINIMUM_HEIGHT)

                    && (y_pixel * INV_SCALE <  waiting_remaining 
                                            + duration_remaining
                                            + current_note[1].waiting 
                                            + MINIMUM_HEIGHT 
                                            + (current_note[1].long[column] ? current_note[1].duration : 0) ) ) 

                        note_fill_nxt[column][y_pixel] = 1'b1;

                end else if(current_note[2].buttons[column]) begin

                    if((y_pixel * INV_SCALE >= waiting_remaining 
                                            + duration_remaining 
                                            + current_note[1].waiting
                                            + current_note[1].duration
                                            + current_note[2].waiting
                                            - MINIMUM_HEIGHT)

                    && (y_pixel * INV_SCALE <  waiting_remaining 
                                            + duration_remaining
                                            + current_note[1].waiting
                                            + current_note[1].duration
                                            + current_note[2].waiting 
                                            + MINIMUM_HEIGHT 
                                            + (current_note[2].long[column] ? current_note[2].duration : 0) ) ) 

                        note_fill_nxt[column][y_pixel] = 1'b1;

                end else note_fill_nxt[column][y_pixel] = 1'b0;
                
            end
        end
    end
end

endmodule