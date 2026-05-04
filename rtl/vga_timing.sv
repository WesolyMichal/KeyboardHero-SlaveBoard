/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Vga timing controller.
 */

module vga_timing (
        input  logic clk,
        input  logic rst_n,
        output logic [10:0] vcount,
        output logic vsync,
        output logic vblnk,
        output logic [10:0] hcount,
        output logic hsync,
        output logic hblnk
    );

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;

    logic [10:0] vcount_nxt, hcount_nxt;
    logic vsync_nxt, vblnk_nxt, hsync_nxt, hblnk_nxt;

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            vcount <= '0;
            hcount <= '0;
            vsync <= '0;
            vblnk <= 0;
            hsync <= 0;
            hblnk <= 0;
        end else begin
            vcount <= vcount_nxt;
            hcount <= hcount_nxt;
            vsync <= vsync_nxt;
            vblnk <= vblnk_nxt;
            hsync <= hsync_nxt;
            hblnk <= hblnk_nxt;
        end

end

always_comb begin
       
    hcount_nxt = hcount;
    vcount_nxt = vcount;
    hblnk_nxt  = hblnk;
    vblnk_nxt  = vblnk;
    hsync_nxt  = hsync;
    vsync_nxt  = vsync;

        
   if (hcount == HOR_TOTAL_TIME - 1) begin
       hcount_nxt = 0;
        hblnk_nxt = 0;
        if (vcount == VER_TOTAL_TIME - 1) begin
            vcount_nxt = 0;
            vblnk_nxt = 0;
        end else begin
            vcount_nxt = vcount + 1;
            if (vcount == VER_BLANK_START - 1) 
                vblnk_nxt = 1;
        end
    end else begin
        hcount_nxt = hcount + 1;
        if (hcount == HOR_BLANK_START - 1) 
           hblnk_nxt = 1;
    end

        
    hsync_nxt = (hcount >= HOR_SYNC_START - 1) && (hcount < HOR_SYNC_START + HOR_SYNC_TIME - 1);
        
    if ((vcount >= VER_SYNC_START - 1) && (hcount == HOR_TOTAL_TIME - 1)) begin
        vsync_nxt = (vcount < VER_SYNC_START + VER_SYNC_TIME- 1);
    end else begin
        vsync_nxt = vsync;
    end
end


endmodule
