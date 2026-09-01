/*
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Jakub Suder
 *
 * Description:
 * This is the ROM for the 'crowd2_color.data' bitmap.
 * WIDTH = 320 px, HEIGHT = 216 px
 * Address is a 17-bit number, calculated as addry * 320 + addrx.
 * Bitmap is stored as 2-bit values, where each value corresponds to a color:
 * 00 - #FFF,
 * 01 - #322,
 * 10 - #655,
 * 11 - #977,
 * The output 'crowd2_px' is 12-bit number with concatenated
 * red, green and blue color values (4-bit each).
 */

module crowd2_rom (
    input  logic clk,
    input  logic [16:0] addr, 
    output logic [11:0] crowd2_px
); 

    logic [1:0] crowd2_rom_reg;

    (* rom_style = "block" *) logic [1:0] rom [0:69119];

    initial begin
        $readmemb("../../rtl/data/crowd2_color.data", rom);
    end

    always_ff @(posedge clk) begin
        crowd2_rom_reg <= rom[addr];
    end

    always_comb begin
        if (addr < 17'd69120) begin
            case(crowd2_rom_reg)
                2'b00: crowd2_px = 12'hfff;
                2'b01: crowd2_px = 12'h322;
                2'b10: crowd2_px = 12'h655;
                2'b11: crowd2_px = 12'h977;
            endcase
        end else
            crowd2_px = 12'h000;
    end

endmodule