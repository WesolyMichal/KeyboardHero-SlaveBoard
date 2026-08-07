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
                in_bar_nxt = '0;

                if(current_note[0].buttons[COLUMN]) begin
                    automatic logic [15:0] margin       = (current_note[0].long[COLUMN]) ? 0 : MINIMUM_HEIGHT;
                    automatic logic [31:0] bottom_bound = (waiting_remaining > margin) ? (waiting_remaining - margin) : '0;
                    automatic logic [31:0] top_bound    = waiting_remaining + margin + (current_note[0].long[COLUMN] ? duration_remaining : '0);
        
                    if((y_scaled >= bottom_bound) && (y_scaled < top_bound))
                        in_bar_nxt = '1;
                end
            end
        1:
            always_comb begin
                // ==================== NUTA 1 ====================
                in_bar_nxt = '0;

                if(current_note[1].buttons[COLUMN]) begin
                    automatic logic [15:0] margin       = (current_note[1].long[COLUMN]) ? 0 : MINIMUM_HEIGHT;
                    automatic logic [31:0] base_pos     = waiting_remaining + duration_remaining + current_note[1].waiting;
                    automatic logic [31:0] bottom_bound = (base_pos > margin) ? (base_pos - margin) : '0;
                    automatic logic [31:0] top_bound    = base_pos + margin + (current_note[1].long[COLUMN] ? current_note[1].duration : '0);
        
                    if((y_scaled >= bottom_bound) && (y_scaled < top_bound))
                        in_bar_nxt = '1;
                end
            end
        2:
            always_comb begin
                // ==================== NUTA 2 ====================
                in_bar_nxt = '0;

                if(current_note[2].buttons[COLUMN]) begin
                    automatic logic [15:0] margin       = (current_note[2].long[COLUMN]) ? 0 : MINIMUM_HEIGHT;
                    automatic logic [31:0] base_pos     = waiting_remaining + duration_remaining + current_note[1].waiting + current_note[1].duration + current_note[2].waiting;
                    automatic logic [31:0] bottom_bound = (base_pos > margin) ? (base_pos - margin) : '0;
                    automatic logic [31:0] top_bound    = base_pos + margin + (current_note[2].long[COLUMN] ? current_note[2].duration : '0);
        
                    if((y_scaled >= bottom_bound) && (y_scaled < top_bound))
                        in_bar_nxt = '1;
                end
            end
    endcase
endgenerate

endmodule