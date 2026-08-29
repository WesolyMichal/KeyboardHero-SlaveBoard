module brickwall_rom (
    input  logic clk,
    input  logic [17:0] addr, // address = addry * 600 + addrx
    output logic [11:0] brickwall_px
);
// image rom content of: brickwall.png
// WIDTH = 600
// HEIGHT = 274
// Number of colors = 4
// Color Palette (Index: R, G, B)
//   0: 73, 74, 76
//   1: 109, 111, 111
//   2: 36, 37, 37
//   3: 56, 57, 57
//   Kolor 0: #444
//   Kolor 1: #666
//   Kolor 2: #222
//   Kolor 3: #333

    (* rom_style = "block" *) logic [1:0] rom [0:164399];

    initial begin
        $readmemb("../../rtl/data/brickwall_4color_indexed.data", rom);
    end

    always_ff @(posedge clk) begin
        if (addr < 18'd164400) begin
            case (rom[addr])
                2'b00: brickwall_px <= 12'h444; // Color 0
                2'b01: brickwall_px <= 12'h666; // Color 1
                2'b10: brickwall_px <= 12'h222; // Color 2
                2'b11: brickwall_px <= 12'h333; // Color 3 
            endcase
        end else begin
            brickwall_px <= '0;
        end
    end

endmodule