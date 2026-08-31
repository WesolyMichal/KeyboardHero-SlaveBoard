/*
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Jakub Suder
 *
 * Description:
 * This is the ROM for the 'brickwall.data' bitmap used as a texture of background.
 * WIDTH = 600 px, HEIGHT = 274 px
 * Address is a 18-bit number, calculated as addry * 600 + addrx.
 * Bitmap is stored as 2-bit values, where each value corresponds to a color:
 * 00 - #444, 
 * 01 - #666, 
 * 10 - #222, 
 * 11 - #333
 * The output 'brickwall_px' is 12-bit number with concatenated
 * red, green and blue color values (4-bit each).
 */

module brickwall_rom (
    input  logic clk,
    input  logic [17:0] addr,
    output logic [11:0] brickwall_px
);
    logic [1:0] brickwall_rom_reg;

    (* rom_style = "block" *) logic [1:0] rom [0:164399];

    initial begin
        $readmemb("../../rtl/data/brickwall.data", rom);
    end

    always_ff @(posedge clk) begin 
            brickwall_rom_reg <= rom[addr];
    end

    always_comb begin
        if (addr < 18'd164400) begin
            case (brickwall_rom_reg)
                2'b00: brickwall_px = 12'h444;
                2'b01: brickwall_px = 12'h666;
                2'b10: brickwall_px = 12'h222;
                2'b11: brickwall_px = 12'h333; 
            endcase
        end else begin
            brickwall_px = 12'h000;
        end
    end

endmodule