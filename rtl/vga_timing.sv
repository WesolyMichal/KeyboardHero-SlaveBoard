import vga_pkg::*;

module vga_timing (
        input  logic clk,
        input  logic rst_n,
        output vga_if vga_out
    );

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;

    vga_if vga_out_nxt;

    always_ff @(posedge clk) begin

        if (!rst_n) begin
            vga_out.vcount <= '0;
            vga_out.hcount <= '0;
            vga_out.vsync <= '0;
            vga_out.vblnk <= 0;
            vga_out.hsync <= 0;
            vga_out.hblnk <= 0;
            vga_out.rgb <= '0;
        end else begin
            vga_out.vcount <= vga_out_nxt.vcount;
            vga_out.hcount <= vga_out_nxt.hcount;
            vga_out.vsync <= vga_out_nxt.vsync;
            vga_out.vblnk <= vga_out_nxt.vblnk;
            vga_out.hsync <= vga_out_nxt.hsync;
            vga_out.hblnk <= vga_out_nxt.hblnk;
            vga_out.rgb <= vga_out_nxt.rgb;
        end

end

always_comb begin
    vga_out_nxt = vga_out;
        
    if (vga_out.hcount == HOR_TOTAL_TIME - 1) begin
        vga_out_nxt.hcount = 0;
        vga_out_nxt.hblnk = 0;
        if (vga_out.vcount == VER_TOTAL_TIME - 1) begin
            vga_out_nxt.vcount = 0;
            vga_out_nxt.vblnk = 0;
        end else begin
            vga_out_nxt.vcount = vga_out.vcount + 1;
            if (vga_out.vcount == VER_BLANK_START - 1) 
            vga_out_nxt.vblnk = 1;
        end
    end else begin
        vga_out_nxt.hcount = vga_out.hcount + 1;
        if (vga_out.hcount == HOR_BLANK_START - 1) 
            vga_out_nxt.hblnk = 1;
    end

        
    vga_out_nxt.hsync = (vga_out.hcount >= HOR_SYNC_START - 1) && (vga_out.hcount < HOR_SYNC_START + HOR_SYNC_TIME - 1);
        
    if ((vga_out.vcount >= VER_SYNC_START - 1) && (vga_out.hcount == HOR_TOTAL_TIME - 1)) begin
        vga_out_nxt.vsync = (vga_out.vcount < VER_SYNC_START + VER_SYNC_TIME- 1);
    end else begin
        vga_out_nxt.vsync = vga_out.vsync;
    end
end


endmodule
