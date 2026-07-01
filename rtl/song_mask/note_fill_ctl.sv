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

    input vga_if vga_in,
    output vga_if vga_out
);

logic [15:0] waiting_remaining, duration_remaining;
logic [11:0] rgb_nxt;

always_ff @(posedge clk) begin
    if(!rst_n) begin
        enable_out  <= '0;
        vga_out     <= '0;
    end else begin
        enable_out<= enable_in;
        vga_out.hblnk <= vga_in.hblnk;
        vga_out.hcount <= vga_in.hcount;
        vga_out.hsync <= vga_in.hsync;
        vga_out.rgb <= rgb_nxt;
        vga_out.vblnk <= vga_in.vblnk;
        vga_out.vcount <= vga_in.vcount;
        vga_out.vsync <= vga_in.vsync;
    end
end

always_comb begin

    rgb_nxt = vga_in.rgb;
    
    if(timer < current_note[0].waiting) begin
        duration_remaining = current_note[0].duration;
        waiting_remaining = current_note[0].waiting - timer;
    end else if(timer < current_note[0].waiting + current_note[0].duration) begin
        duration_remaining = current_note[0].duration - (timer - current_note[0].waiting);
        waiting_remaining = '0;
    end else begin
        duration_remaining = '0;
        waiting_remaining = '0;
    end

    if (enable_in && vga_in.vcount < NOTE_DISPLAY_HEIGHT) begin

        automatic logic [10:0] y_pixel = NOTE_DISPLAY_HEIGHT - 1 - vga_in.vcount;
        automatic logic [31:0] y_scaled = y_pixel * INV_SCALE;

        for(logic [2:0] column = 0; column < 6; column++) begin

            if((vga_in.hcount >= COLUMN_XPOS[column]) && (vga_in.hcount < COLUMN_XPOS[column] + COLUMN_WIDTH)) begin
        
                // ==================== NUTA 0 ====================
                if(current_note[0].buttons[column]) begin
                    automatic logic [15:0] margin       = (current_note[0].long[column]) ? 0 : MINIMUM_HEIGHT;
                    automatic logic [31:0] bottom_bound = (waiting_remaining > margin) ? (waiting_remaining - margin) : '0;
                    automatic logic [31:0] top_bound    = waiting_remaining + margin + (current_note[0].long[column] ? duration_remaining : '0);
        
                    if((y_scaled >= bottom_bound) && (y_scaled < top_bound))
                        rgb_nxt = COLUMN_COLOURS[column];
                end
        
                // ==================== NUTA 1 ====================
                if(current_note[1].buttons[column]) begin
                    automatic logic [15:0] margin       = (current_note[1].long[column]) ? 0 : MINIMUM_HEIGHT;
                    automatic logic [31:0] base_pos     = waiting_remaining + duration_remaining + current_note[1].waiting;
                    automatic logic [31:0] bottom_bound = (base_pos > margin) ? (base_pos - margin) : '0;
                    automatic logic [31:0] top_bound    = base_pos + margin + (current_note[1].long[column] ? current_note[1].duration : '0);
        
                    if((y_scaled >= bottom_bound) && (y_scaled < top_bound))
                        rgb_nxt = COLUMN_COLOURS[column];
                end
        
                // ==================== NUTA 2 ====================
                if(current_note[2].buttons[column]) begin
                    automatic logic [15:0] margin       = (current_note[2].long[column]) ? 0 : MINIMUM_HEIGHT;
                    automatic logic [31:0] base_pos     = waiting_remaining + duration_remaining + current_note[1].waiting + current_note[1].duration + current_note[2].waiting;
                    automatic logic [31:0] bottom_bound = (base_pos > margin) ? (base_pos - margin) : '0;
                    automatic logic [31:0] top_bound    = base_pos + margin + (current_note[2].long[column] ? current_note[2].duration : '0);
        
                    if((y_scaled >= bottom_bound) && (y_scaled < top_bound))
                        rgb_nxt = COLUMN_COLOURS[column];
                end
        
            end
        end
    end
end

endmodule