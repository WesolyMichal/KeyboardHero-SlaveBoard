/*
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Jakub Suder
 *
 * Description:
 * This is the ROM for the 'crowd1_color.data' bitmap.
 * WIDTH = 320 px, HEIGHT = 195 px
 * Address is a 17-bit number, calculated as addry * 320 + addrx.
 * Bitmap is stored as 2-bit values, where each value corresponds to a color:
 * 00 - #FFF, 
 * 01 - #522
 * 10 - #A88
 * 11 - #634
 * The output 'crowd1_px' is 12-bit number with concatenated
 * red, green and blue color values (4-bit each).
 */

module crowd1_rom (
    input  logic clk,
    input  logic [16:0] addr,
    output logic [11:0] crowd1_px
);

    logic [1:0] crowd1_rom_reg;

    (* rom_style = "block" *) logic [1:0] rom [0:62399];

    initial begin
        $readmemb("../../rtl/data/crowd1_color.data", rom);
    end

    always_ff @(posedge clk) begin
        crowd1_rom_reg <= rom[addr];
    end

    always_comb begin
        if(addr < 16'd62400) begin
            case(crowd1_rom_reg)
                2'b00: crowd1_px = 12'hfff;
                2'b01: crowd1_px = 12'h522;
                2'b10: crowd1_px = 12'hA88;
                2'b11: crowd1_px = 12'h634;
            endcase
        end else 
            crowd1_px = 12'h000;
    end
endmodule