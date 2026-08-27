module sticker (
    input  logic clk,
    input  logic [17:0] addr, // address = {addry * 400 + addrx}
    output logic [11:0] sticker_px
);
// image rom content of: /data/sticker.png
// WIDTH = 400
// HEIGHT = 447

    (* rom_style = "block" *) logic [11:0] rom [0:178799];

    initial begin
        $readmemb("../../rtl/data/sticker.data", rom);
    end

    always_ff @(posedge clk) begin
        if (addr < 18'd178800) begin   
            sticker_px <= rom[addr];
        end else begin
            sticker_px <= '0;
        end
    end

endmodule