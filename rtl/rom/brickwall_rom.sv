module brickwall (
    input  logic clk,
    input  logic [17:0] addr, // address = addry * 600 + addrx
    output logic [11:0] brickwall_px
);
// image rom content of: /data/brickwall.data
// WIDTH = 600
// HEIGHT = 274

    (* rom_style = "block" *) logic [11:0] rom [0:164399];

    initial begin
        $readmemb("../../rtl/data/brickwall.data", rom);
    end

    always_ff @(posedge clk) begin
        if (addr < 18'd164400) begin   
            brickwall_px <= rom[addr];
        end else begin
            brickwall_px <= '0;
        end
    end

endmodule