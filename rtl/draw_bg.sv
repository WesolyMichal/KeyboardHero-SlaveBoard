/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Draw background.
 */

module draw_bg (
        input  logic clk,
        input  logic rst_n,

        input  logic [10:0] vcount_in,
        input  logic        vsync_in,
        input  logic        vblnk_in,
        input  logic [10:0] hcount_in,
        input  logic        hsync_in,
        input  logic        hblnk_in,

        output logic [10:0] vcount_out,
        output logic        vsync_out,
        output logic        vblnk_out,
        output logic [10:0] hcount_out,
        output logic        hsync_out,
        output logic        hblnk_out,

        output logic [11:0] rgb_out
    );

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;


    /**
     * Local variables and signals
     */

    logic [11:0] rgb_nxt;


    /**
     * Internal logic
     */

    always_ff @(posedge clk or negedge rst_n) begin : bg_ff_blk
        if (!rst_n) begin
            vcount_out <= '0;
            vsync_out  <= '0;
            vblnk_out  <= '0;
            hcount_out <= '0;
            hsync_out  <= '0;
            hblnk_out  <= '0;
            rgb_out    <= '0;
        end else begin
            vcount_out <= vcount_in;
            vsync_out  <= vsync_in;
            vblnk_out  <= vblnk_in;
            hcount_out <= hcount_in;
            hsync_out  <= hsync_in;
            hblnk_out  <= hblnk_in;
            rgb_out    <= rgb_nxt;
        end
    end

    always_comb begin : bg_comb_blk
        if (vblnk_in || hblnk_in) begin             // Blanking region:
            rgb_nxt = 12'h0_0_0;                    // - make it black.
        end else begin                              // Active region:
            if (vcount_in == 0)                     // - top edge:
                rgb_nxt = 12'hf_f_0;                // - - make a yellow line.
            else if (vcount_in == VER_PIXELS - 1)   // - bottom edge:
                rgb_nxt = 12'hf_0_0;                // - - make a red line.
            else if (hcount_in == 1)                // - left edge:
                rgb_nxt = 12'h0_f_0;                // - - make a green line.
            else if (hcount_in == HOR_PIXELS - 1)   // - right edge:
                rgb_nxt = 12'h0_0_f;                // - - make a blue line.

    // Lewa linia M
            else if ((hcount_in >= 90 && hcount_in <= 100) && (vcount_in >= 300 && vcount_in <= 400))
                rgb_nxt = 12'h0_0_f; 

    // Prawa linia M
            else  if ((hcount_in >= 170 && hcount_in <= 180) && (vcount_in >= 300 && vcount_in <= 400))
                rgb_nxt = 12'h0_0_f; 

    
    // kwadraty na przeątnej M
            else  if ((hcount_in >= 100 && hcount_in <= 110) && (vcount_in >= 310 && vcount_in <= 320))
                rgb_nxt = 12'h0_0_f; 

            else  if ((hcount_in >= 110 && hcount_in <= 120) && (vcount_in >= 320 && vcount_in <= 330))
                rgb_nxt = 12'h0_0_f; 

            else  if ((hcount_in >= 120 && hcount_in <= 130) && (vcount_in >= 330 && vcount_in <= 340))
                rgb_nxt = 12'h0_0_f; 

            else  if ((hcount_in >= 130 && hcount_in <= 140) && (vcount_in >= 340 && vcount_in <= 350))
                rgb_nxt = 12'h0_0_f; 

            else  if ((hcount_in >= 140 && hcount_in <= 150) && (vcount_in >= 330 && vcount_in<= 340))
                rgb_nxt = 12'h0_0_f; 

            else  if ((hcount_in >= 150 && hcount_in <= 160) && (vcount_in >= 320 && vcount_in<= 330))
                rgb_nxt = 12'h0_0_f; 

            else  if ((hcount_in >= 160 && hcount_in <= 170) && (vcount_in >= 310 && vcount_in <= 320))
                rgb_nxt = 12'h0_0_f; 
    // Litera T

            else  if ((hcount_in >= 200 && hcount_in <= 270) && (vcount_in >= 300 && vcount_in <= 310))
                rgb_nxt = 12'h0_0_f; 

            else  if ((hcount_in >= 230 && hcount_in <= 240) && (vcount_in >= 300 && vcount_in <= 400))
                rgb_nxt = 12'h0_0_f; 



// Lewa linia M 2
            else if ((hcount_in >= 510 && hcount_in <= 520) && (vcount_in >= 300 && vcount_in <= 400))
            rgb_nxt = 12'h0_0_f; 

// Prawa linia M 2
        else  if ((hcount_in >= 590 && hcount_in <= 600) && (vcount_in >= 300 && vcount_in <= 400))
            rgb_nxt = 12'h0_0_f; 


// kwadraty na przeątnej M 2
        else  if ((hcount_in >= 520 && hcount_in <= 530) && (vcount_in >= 310 && vcount_in <= 320))
            rgb_nxt = 12'h0_0_f; 

        else  if ((hcount_in >= 530 && hcount_in <= 540) && (vcount_in >= 320 && vcount_in <= 330))
            rgb_nxt = 12'h0_0_f; 

        else  if ((hcount_in >= 540 && hcount_in <= 550) && (vcount_in >= 330 && vcount_in <= 340))
            rgb_nxt = 12'h0_0_f; 

        else  if ((hcount_in >= 550 && hcount_in <= 560) && (vcount_in >= 340 && vcount_in <= 350))
            rgb_nxt = 12'h0_0_f; 

        else  if ((hcount_in >= 560 && hcount_in <= 570) && (vcount_in >= 330 && vcount_in<= 340))
            rgb_nxt = 12'h0_0_f; 

        else  if ((hcount_in >= 570 && hcount_in <= 580) && (vcount_in >= 320 && vcount_in<= 330))
            rgb_nxt = 12'h0_0_f; 

        else  if ((hcount_in >= 580 && hcount_in <= 590) && (vcount_in >= 310 && vcount_in <= 320))
            rgb_nxt = 12'h0_0_f; 
      
        //lewa linia W
        else if ((hcount_in >= 620 && hcount_in <= 630) && (vcount_in >= 300 && vcount_in <= 400))
            rgb_nxt = 12'h0_0_f; 
        //prawa linia W
        else  if ((hcount_in >= 700 && hcount_in <= 710) && (vcount_in >= 300 && vcount_in <= 400))
            rgb_nxt = 12'h0_0_f; 
        // kwadraty na przeątnej W
        else  if ((hcount_in >= 630 && hcount_in <= 640) && (vcount_in >= 380 && vcount_in <= 390))
                rgb_nxt = 12'h0_0_f; 

        else  if ((hcount_in >= 640 && hcount_in <= 650) && (vcount_in >= 370 && vcount_in <= 380))
                rgb_nxt = 12'h0_0_f; 

        else  if ((hcount_in >= 650 && hcount_in <= 660) && (vcount_in >= 360 && vcount_in <= 370))
                rgb_nxt = 12'h0_0_f; 

        else  if ((hcount_in >= 660 && hcount_in <= 670) && (vcount_in >= 350 && vcount_in <= 360))
                rgb_nxt = 12'h0_0_f; 

        else  if ((hcount_in >= 670 && hcount_in <= 680) && (vcount_in >= 360 && vcount_in<= 370))
                rgb_nxt = 12'h0_0_f; 

        else  if ((hcount_in >= 680 && hcount_in <= 690) && (vcount_in >= 370 && vcount_in<= 380))
                rgb_nxt = 12'h0_0_f; 

        else  if ((hcount_in >= 690 && hcount_in <= 700) && (vcount_in >= 380 && vcount_in <= 390))
                rgb_nxt = 12'h0_0_f; 
                else
                    rgb_nxt = 12'h8_8_8; 
            end
    end
endmodule