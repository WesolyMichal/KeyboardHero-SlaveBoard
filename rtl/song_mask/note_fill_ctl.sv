import game_pkg::*;
import song_mask_pkg::*;

module note_fill_ctl #(
    parameter INV_SCALE = 20,
    parameter MINIMUM_HEIGHT = INV_SCALE * 10
)(
    input logic clk,
    input logic rst_n,
    input logic enable_in,
    
    input logic [31:0] timer,
    input note_t current_note [0:2],

    output logic enable_out,
    output logic note_fill[0:5][0:SCREEN_HEIGHT-1],

    input vga_if vga_in,
    output vga_if vga_out
);

logic note_fill_nxt[0:5][0:SCREEN_HEIGHT-1];

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        foreach(note_fill[i, j])
            note_fill[i][j] <= '0;
        enable_out<= '0;
    end else begin
        note_fill <= note_fill_nxt;
        enable_out<= enable_in;
    end
end

always_comb begin
    logic [15:0] waiting_remaining, duration_remaining;

    note_fill_nxt = note_fill;

    waiting_remaining = (timer < current_note[0].waiting) ? (current_note[0].waiting - timer) : 0;
    duration_remaining = (timer < current_note[0].waiting) ? current_note[0].duration : current_note[0].duration - (timer - current_note[0].waiting);

    if(!enable_in) begin
        foreach(note_fill_nxt[i, j])
            note_fill_nxt[i][j] = '0;
    end else begin
        for(logic [2:0] column = 0; column < 6; column++) begin
            for(logic [11:0] y_pixel = 0; y_pixel < SCREEN_HEIGHT; y_pixel++) begin

                note_fill_nxt[column][y_pixel] = 1'b0;

                if(current_note[0].buttons[column]) begin

                    if((y_pixel * INV_SCALE >= waiting_remaining 
                                            - ((current_note[0].long[column]) ? 0 : MINIMUM_HEIGHT) )

                    && (y_pixel * INV_SCALE <  waiting_remaining 
                                            + ((current_note[0].long[column]) ? 0 : MINIMUM_HEIGHT)
                                            + (current_note[0].long[column] ? duration_remaining : 0) ) ) 

                        note_fill_nxt[column][y_pixel] = 1'b1;
                end

                if(current_note[1].buttons[column]) begin

                    if((y_pixel * INV_SCALE >= waiting_remaining 
                                            + duration_remaining 
                                            + current_note[1].waiting 
                                            - ((current_note[1].long[column]) ? 0 : MINIMUM_HEIGHT))

                    && (y_pixel * INV_SCALE <  waiting_remaining 
                                            + duration_remaining
                                            + current_note[1].waiting 
                                            + ((current_note[1].long[column]) ? 0 : MINIMUM_HEIGHT) 
                                            + (current_note[1].long[column] ? current_note[1].duration : 0) ) ) 

                        note_fill_nxt[column][y_pixel] = 1'b1;
                end

                if(current_note[2].buttons[column]) begin

                    if((y_pixel * INV_SCALE >= waiting_remaining 
                                            + duration_remaining 
                                            + current_note[1].waiting
                                            + current_note[1].duration
                                            + current_note[2].waiting
                                            - ((current_note[2].long[column]) ? 0 : MINIMUM_HEIGHT))

                    && (y_pixel * INV_SCALE <  waiting_remaining 
                                            + duration_remaining
                                            + current_note[1].waiting
                                            + current_note[1].duration
                                            + current_note[2].waiting 
                                            + ((current_note[2].long[column]) ? 0 : MINIMUM_HEIGHT)
                                            + (current_note[2].long[column] ? current_note[2].duration : 0) ) ) 

                        note_fill_nxt[column][y_pixel] = 1'b1;
                end
                
            end
        end
    end
end

delay #(
    .CLK_DEL(1),
    .WIDTH(38)
)vga_delay(
    .clk,
    .rst_n,
    .din(vga_in),
    .dout(vga_out)
);

endmodule