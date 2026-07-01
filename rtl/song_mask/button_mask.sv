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

localparam BORDER_WIDTH = 1;
localparam BUTTON_WIDTH = 60;
localparam BUTTON_FRAME = 1;

localparam [10:0] NECK_LINES_X [0:6] = {320, 384, 448, 512, 576, 640, 704};

localparam RED_BUTTON_X = NECK_LINES_X [0] + BORDER_WIDTH+ BUTTON_FRAME;      //322
//ramka x 322 i 382  y 642 i 703
localparam GREEN_BUTTON_X = NECK_LINES_X [1] + BORDER_WIDTH + BUTTON_FRAME;    //386
localparam BLUE_BUTTON_X = NECK_LINES_X [2] + BORDER_WIDTH + BUTTON_FRAME;     //450
localparam YELLOW_BUTTON_X = NECK_LINES_X [3] + BORDER_WIDTH + BUTTON_FRAME;   //514
localparam MAGENTA_BUTTON_X = NECK_LINES_X [4] + BORDER_WIDTH + BUTTON_FRAME;  //578
localparam CYAN_BUTTON_X = NECK_LINES_X [5] + BORDER_WIDTH + BUTTON_FRAME;     //642

logic [11:0] rgb_nxt;


always_ff @(posedge clk, negedge rst_n) begin
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

always_comb begin //pozycje przycisków
    rgb_nxt = vga_in.rgb;
    if(enable_in) begin
        if (vga_in.vcount >= NOTE_DISPLAY_HEIGHT + BORDER_WIDTH + BUTTON_FRAME && vga_in.vcount <= NOTE_DISPLAY_HEIGHT + BORDER_WIDTH + BUTTON_FRAME+ BUTTON_WIDTH +BUTTON_FRAME) begin 
            if((vga_in.hcount >= RED_BUTTON_X) && (vga_in.hcount <= RED_BUTTON_X + BUTTON_WIDTH + BUTTON_FRAME)) begin
                rgb_nxt = COLOUR_RED;
                if((vga_in.hcount > RED_BUTTON_X) && (vga_in.hcount < RED_BUTTON_X + BUTTON_WIDTH+ BUTTON_FRAME)) begin
                    if(!buttons[0]) rgb_nxt = vga_in.rgb;
                end

            end else if((vga_in.hcount >= GREEN_BUTTON_X) && (vga_in.hcount <= GREEN_BUTTON_X + BUTTON_WIDTH + BUTTON_FRAME)) begin
                rgb_nxt = COLOUR_GREEN;
                if((vga_in.hcount > GREEN_BUTTON_X) && (vga_in.hcount < GREEN_BUTTON_X + BUTTON_WIDTH + BUTTON_FRAME)) begin
                    if(!buttons[1]) rgb_nxt = vga_in.rgb;
                end

            end else if ((vga_in.hcount >= BLUE_BUTTON_X) && (vga_in.hcount <= BLUE_BUTTON_X + BUTTON_WIDTH + BUTTON_FRAME)) begin
                rgb_nxt = COLOUR_BLUE;
                if ((vga_in.hcount > BLUE_BUTTON_X) && (vga_in.hcount < BLUE_BUTTON_X + BUTTON_WIDTH + BUTTON_FRAME)) begin
                    if(!buttons[2]) rgb_nxt = vga_in.rgb;
                end

            end else if ((vga_in.hcount >= YELLOW_BUTTON_X) && (vga_in.hcount <= YELLOW_BUTTON_X + BUTTON_WIDTH + BUTTON_FRAME)) begin
                rgb_nxt = COLOUR_YELLOW;
                if ((vga_in.hcount > YELLOW_BUTTON_X) && (vga_in.hcount < YELLOW_BUTTON_X + BUTTON_WIDTH + BUTTON_FRAME)) begin
                    if(!buttons[3]) rgb_nxt = vga_in.rgb;
                end

            end else if ((vga_in.hcount >= MAGENTA_BUTTON_X) && (vga_in.hcount <= MAGENTA_BUTTON_X + BUTTON_WIDTH + BUTTON_FRAME)) begin
                rgb_nxt = COLOUR_MAGENTA;
                if ((vga_in.hcount > MAGENTA_BUTTON_X) && (vga_in.hcount < MAGENTA_BUTTON_X + BUTTON_WIDTH + BUTTON_FRAME)) begin
                    if(!buttons[4]) rgb_nxt = vga_in.rgb;
                end

            end else if ((vga_in.hcount >= CYAN_BUTTON_X) && (vga_in.hcount <= CYAN_BUTTON_X + BUTTON_WIDTH + BUTTON_FRAME)) begin
                rgb_nxt = COLOUR_CYAN;
                if ((vga_in.hcount > CYAN_BUTTON_X) && (vga_in.hcount < CYAN_BUTTON_X + BUTTON_WIDTH + BUTTON_FRAME)) begin
                    if(!buttons[5]) rgb_nxt = vga_in.rgb;
                end
            end
            
        end
    end
end



endmodule