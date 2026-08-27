module crowd2 (
    input  logic clk,
    input  logic [15:0] addr, // address = {addry[7:0], addrx[7:0]}
    output logic [11:0] crowd2_px
);
// image rom content of: /data/crowd2.png
// WIDTH = 256
// HEIGHT = 235

    (* rom_style = "block" *) logic [11:0] rom [0:60159];

    initial begin
        $readmemb("../../rtl/data/crowd2.data", rom);
    end

    always_ff @(posedge clk) begin
        if (addr < 16'd60160) begin   
            crowd2_px <= rom[addr];
        end else begin
            crowd2_px <= '0;
        end
    end

endmodule