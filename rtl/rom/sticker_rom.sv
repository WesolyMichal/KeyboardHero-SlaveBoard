module sticker_rom (
    input  logic clk,
    input  logic [17:0] addr, // address = {addry * 400 + addrx}
    output logic [11:0] sticker_px
);
// image rom content of: sticker.png
// WIDTH = 300
// HEIGHT = 335
// Number of colors = 4
// Color Palette (Index: R, G, B) / 12-bit Hex (4 bits per channel)
//   0: RGB(228, 224, 223) - #EED
//   1: RGB(18, 16, 14) - #110
//   2: RGB(147, 141, 136) - #988
//   3: RGB(68, 69, 84) - #445

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