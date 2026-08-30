/*
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Jakub Suder
 *
 * Description:
 * This is the ROM for the 'crowd1_bw.data' bitmap.
 * WIDTH = 256 px, HEIGHT = 212 px
 * Address is a 16-bit number, composed of the concatenated
 * 8-bit y and 8-bit x pixel coordinates.
 * Bitmap is stored as 1-bit values, where each value corresponds to a color:
 * 0 - #000, 
 * 1 - #fff
 * The output 'crowd1_px' is 12-bit number with concatenated
 * red, green and blue color values (4-bit each).
 */

module crowd1_rom (
    input  logic clk,
    input  logic [15:0] addr,
    output logic [11:0] crowd1_px
);

    (* rom_style = "block" *) logic [0:0] rom [0:54271];

    initial begin
        $readmemb("../../rtl/data/crowd1_bw.data", rom);
    end

    always_ff @(posedge clk) begin
        if ((addr < 16'd54272) && (rom[addr] == 1'b1)) begin
            crowd1_px <= 12'hfff;
        end else begin
            crowd1_px <= '0;
        end
    end

endmodule