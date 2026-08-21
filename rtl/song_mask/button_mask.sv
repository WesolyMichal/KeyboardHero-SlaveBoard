import song_mask_pkg::*;
import vga_pkg::*;

module button_mask(
    input logic clk,
    input logic rst_n,
    
    input logic [5:0] buttons,

    input logic enable_in,

    input vga_if vga_in,
    output vga_if vga_out
);

localparam BUTTON_WIDTH = 60;//61
localparam BUTTON_Y = NOTE_DISPLAY_HEIGHT + 2;//642
localparam BUTTON_OFFSET = 2;//2

logic [11:0] rgb_nxt;
logic [10:0] button_x;
logic [2:0] button_index;
logic button_selected;


always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        vga_out.rgb <= '0;
        vga_out     <= '0;
    end
    else begin
        vga_out.rgb <=rgb_nxt;
        vga_out.hblnk <= vga_in.hblnk;
        vga_out.hcount <= vga_in.hcount;
        vga_out.hsync <= vga_in.hsync;
        vga_out.vblnk <= vga_in.vblnk;
        vga_out.vcount <= vga_in.vcount;
        vga_out.vsync <= vga_in.vsync;
    end
end

always_comb begin
    rgb_nxt = vga_in.rgb;
    button_x = '0;
    button_index = '0;
    button_selected = 1'b0;

    if (vga_in.hcount >= COLUMN_XPOS[0] + BUTTON_OFFSET &&
                 vga_in.hcount < COLUMN_XPOS[0] + BUTTON_OFFSET + BUTTON_WIDTH) begin
        button_x = COLUMN_XPOS[0] + BUTTON_OFFSET;
        button_index = 3'd0;
        button_selected = 1'b1;
    end else if (vga_in.hcount >= COLUMN_XPOS[1] + BUTTON_OFFSET &&
                 vga_in.hcount < COLUMN_XPOS[1] + BUTTON_OFFSET + BUTTON_WIDTH) begin
        button_x = COLUMN_XPOS[1] + BUTTON_OFFSET;
        button_index = 3'd1;
        button_selected = 1'b1;
    end else if (vga_in.hcount >= COLUMN_XPOS[2] + BUTTON_OFFSET &&
                 vga_in.hcount < COLUMN_XPOS[2] + BUTTON_OFFSET + BUTTON_WIDTH) begin
        button_x = COLUMN_XPOS[2] + BUTTON_OFFSET;
        button_index = 3'd2;
        button_selected = 1'b1;
    end else if (vga_in.hcount >= COLUMN_XPOS[3] + BUTTON_OFFSET &&
                 vga_in.hcount < COLUMN_XPOS[3] + BUTTON_OFFSET + BUTTON_WIDTH) begin
        button_x = COLUMN_XPOS[3] + BUTTON_OFFSET;
        button_index = 3'd3;
        button_selected = 1'b1;
    end else if (vga_in.hcount >= COLUMN_XPOS[4] + BUTTON_OFFSET &&
                 vga_in.hcount < COLUMN_XPOS[4] + BUTTON_OFFSET + BUTTON_WIDTH) begin
        button_x = COLUMN_XPOS[4] + BUTTON_OFFSET;
        button_index = 3'd4;
        button_selected = 1'b1;
    end else if (vga_in.hcount >= COLUMN_XPOS[5] + BUTTON_OFFSET &&
                 vga_in.hcount < COLUMN_XPOS[5] + BUTTON_OFFSET + BUTTON_WIDTH) begin
        button_x = COLUMN_XPOS[5] + BUTTON_OFFSET;
        button_index = 3'd5;
        button_selected = 1'b1;
    end

    if (enable_in && button_selected && vga_in.vcount >= BUTTON_Y && vga_in.vcount < BUTTON_Y + BUTTON_WIDTH) begin
        if (vga_in.hcount == button_x ||
            vga_in.hcount == button_x + BUTTON_WIDTH - 1 ||
            vga_in.vcount == BUTTON_Y ||
            vga_in.vcount == BUTTON_Y + BUTTON_WIDTH - 1 ||
            (buttons[button_index] &&
             vga_in.hcount > button_x &&
             vga_in.hcount < button_x + BUTTON_WIDTH - 1 &&
             vga_in.vcount > BUTTON_Y &&
             vga_in.vcount < BUTTON_Y + BUTTON_WIDTH - 1)) begin
            rgb_nxt = COLUMN_COLOURS[button_index];
        end
    end
end



endmodule