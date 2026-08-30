/*
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Jakub Suder
 *
 * Description:
 * This is the ROM for the 'enter.data' bitmap.
 * WIDTH = 128 px, HEIGHT = 64 px
 * Address is a 13-bit number, composed of the concatenated
 * 6-bit y and 7-bit x pixel coordinates.
 * Bitmap is stored as 1-bit values, where each value corresponds to a color 
 * that can be iverted by the enter state.
 * The output 'enter_px' is 12-bit number with concatenated
 * red, green and blue color values (4-bit each).
 */

module enter_button_rom (
    input  logic clk,
    input  logic [12:0] rom_addr,
    output logic enter_px
);
    
    (* rom_style = "block" *) logic [0:0] rom [0:8191]; 

    initial begin
        $readmemb("../../rtl/data/enter.data", rom);
    end
    
    always_ff @(posedge clk) begin
        enter_px <= rom[rom_addr];
    end

endmodule