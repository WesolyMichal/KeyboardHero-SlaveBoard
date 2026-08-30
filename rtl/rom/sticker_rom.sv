/*
 * Copyright (C) 2026  AGH University of Science and Technology
 * MTM UEC2
 * Author: Jakub Suder
 *
 * Description:
 * This is the ROM for the 'sticker.data' bitmap.
 * WIDTH = 300 px, HEIGHT = 335 px
 * Address is a 18-bit number, calculated as addry * 400 + addrx.
 * Bitmap is stored as 2-bit values, where each value corresponds to a color:
 * 00 - #EED,
 * 01 - #110
 * 10 - #988
 * 11 - #445
 * The output 'sticker_px' is 12-bit number with concatenated
 * red, green and blue color values (4-bit each).
 */
module sticker_rom (
    input  logic clk,
    input  logic [17:0] addr,
    output logic [11:0] sticker_px
);

    (* rom_style = "block" *) logic [1:0] rom [0:100499];

        initial begin
            $readmemb("../../rtl/data/sticker.data", rom);
        end

        always_ff @(posedge clk) begin
            if (addr < 18'd100400) begin   
                case(rom[addr])
                    2'b00: sticker_px <= 12'hEED;
                    2'b01: sticker_px <= 12'h110;
                    2'b10: sticker_px <= 12'h988;
                    2'b11: sticker_px <= 12'h445;
                endcase
            end else begin
                sticker_px <= '0;
            end
        end

endmodule