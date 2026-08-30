module mibombo_rom (
    input  logic clk,
    input  logic [15:0] addr,
    output logic mibombo_out
);
// image rom content of: mibombo.png
// WIDTH = 210
// HEIGHT = 281
// Number of colors = 4
// Color Palette (Index: R, G, B) / 12-bit Hex (4 bits per channel)
//   0: RGB(2, 1, 0) - #000
//   1: RGB(194, 194, 194) - #CCC
//   2: RGB(115, 58, 2) - #730
//   3: RGB(254, 254, 254) - #FFF
    (* rom_style = "block" *) logic [1:0] rom [0:59009];

    initial begin
        $readmemb("../../rtl/data/mibombo_4.data", rom);
    end

    always_ff @(posedge clk) begin
        if (addr < 59010) begin 
            case(rom[addr])
                2'b00: mibombo_out <= 12'hccc;
                2'b01: mibombo_out <= 12'h730;
                2'b10: mibombo_out <= 12'h000;
                2'b11: mibombo_out <= 12'hfff;
            endcase
        end else begin
            mibombo_out <= '0;
        end
    end

endmodule