/*
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Jakub Suder
 *
 * Description:
 * This is the ROM for the 'crowd2_bw.data' bitmap.
 * WIDTH = 256 px, HEIGHT = 235 px
 * Address is a 16-bit number, composed of the concatenated
 * 8-bit y and 8-bit x pixel coordinates.
 * Bitmap is stored as 1-bit values, where each value corresponds to a color:
 * 0 - #000, 
 * 1 - #fff
 * The output 'crowd2_px' is 12-bit number with concatenated
 * red, green and blue color values (4-bit each).
 */

 // image rom content of: crowd2.png
// WIDTH = 128
// HEIGHT = 118
// Format: 0 for black, 1 for white

module crowd2_rom (
    input  logic clk,
    input  logic [15:0] addr, 
    output logic [11:0] crowd2_px
); 

    logic crowd2_rom_reg;

    (* rom_style = "block" *) logic [0:0] rom [0:15103];

    initial begin
        $readmemb("../../rtl/data/crowd2_small_bw.data", rom);
    end

    always_ff @(posedge clk) begin
        crowd2_rom_reg <= rom[addr];
    end

    always_comb begin
        if ((addr < 16'd15104) && (crowd2_rom_reg == 1'b1)) begin
            crowd2_px = 12'hfff;
        end else
            crowd2_px = 12'h000;
    end

endmodule