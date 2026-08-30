/*
 * Copyright (C) 2026  AGH University of Science and Technology
 * MTM UEC2
 * Author: Jakub Suder
 *
 * Description:
 * This is the ROM for the 'star.data' bitmap.
 * WIDTH = 50 px, HEIGHT = 50 px
 * Address is a 13-bit number, calculated as addry * 50 + addrx.
 * Bitmap is stored as 2-bit values, where each value corresponds to
 * a piece of the star:
 * 00 - background,
 * 01 - star outline,
 * 10 - star fill,
 * The output 'star_pixel' is 2-bit number that is used to determine
 * the color of the pixel in the star bitmap.
 */
module star_rom (
    input  logic clk,
    input  logic [12:0] addr, 
    output logic [1:0] star_pixel
);
    (* rom_style = "block" *) logic [1:0] rom [0:8191]; 

    initial begin
        $readmemb("../../rtl/data/star.data", rom);
    end

    always_ff @(posedge clk) begin
        star_pixel <= rom[addr];
    end

endmodule