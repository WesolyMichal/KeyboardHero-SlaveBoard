/*
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Michał Wesołowski
 *
 * Description:
 * Checks whether the y position of the current pixel is within a given column of a given note.
 */
import game_pkg::*;

module fill_checker #(
    parameter COLUMN = 0,
    parameter NOTE_NUM = 0,
    parameter MINIMUM_HEIGHT = 0
)(
    input logic clk,
    input logic rst_n,
    input logic enable,
    input note_t current_note[0:2],
    input logic [15:0] waiting_remaining, 
    input logic [15:0] duration_remaining,
    input logic [31:0] y_scaled,

    output logic in_bar
);

logic in_bar_nxt;


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        in_bar <= '0;
    end else begin
        in_bar <= in_bar_nxt & enable;
    end
end

generate

    case(NOTE_NUM)
        default: 
            always_comb begin
                // ==================== NUTA 0 ====================
                note_t n0;
                logic [15:0] margin;
                logic [31:0] base_pos, bottom_bound, top_bound;

                n0 = current_note[0];
                in_bar_nxt = '0;

                if(n0.buttons[COLUMN]) begin
                    margin       = (n0.long[COLUMN]) ? 0 : MINIMUM_HEIGHT;
                    bottom_bound = (waiting_remaining > margin) ? (waiting_remaining - margin) : '0;
                    top_bound    = waiting_remaining + margin + (n0.long[COLUMN] ? duration_remaining : '0);
        
                    if((y_scaled >= bottom_bound) && (y_scaled < top_bound))
                        in_bar_nxt = '1;
                end
            end
        1:
            always_comb begin
                // ==================== NUTA 1 ====================
                note_t n1;
                logic [15:0] margin;
                logic [31:0] base_pos, bottom_bound, top_bound;

                n1 = current_note[1];
                in_bar_nxt = '0;

                if(n1.buttons[COLUMN]) begin
                    margin       = (n1.long[COLUMN]) ? 0 : MINIMUM_HEIGHT;
                    base_pos     = waiting_remaining + duration_remaining + n1.waiting;
                    bottom_bound = (base_pos > margin) ? (base_pos - margin) : '0;
                    top_bound    = base_pos + margin + (n1.long[COLUMN] ? n1.duration : '0);
        
                    if((y_scaled >= bottom_bound) && (y_scaled < top_bound))
                        in_bar_nxt = '1;
                end
            end
        2:
            always_comb begin
                // ==================== NUTA 2 ====================
                note_t n2, n1;
                logic [15:0] margin;
                logic [31:0] base_pos, bottom_bound, top_bound;

                n2 = current_note[2];
                n1 = current_note[1];
                
                in_bar_nxt = '0;

                if(n2.buttons[COLUMN]) begin
                    margin       = (n2.long[COLUMN]) ? 0 : MINIMUM_HEIGHT;
                    base_pos     = waiting_remaining + duration_remaining + n1.waiting + n1.duration + n2.waiting;
                    bottom_bound = (base_pos > margin) ? (base_pos - margin) : '0;
                    top_bound    = base_pos + margin + (n2.long[COLUMN] ? n2.duration : '0);
        
                    if((y_scaled >= bottom_bound) && (y_scaled < top_bound))
                        in_bar_nxt = '1;
                end
            end
    endcase
endgenerate

endmodule