module crowd1 (
    input  logic clk,
    input  logic [15:0] addr,// address = {addry[7:0], addrx[7:0]}
    output logic [11:0] crowd1_px
);
// image rom content of: /data/crowd1.png
// WIDTH = 256
// HEIGHT = 212

    (* rom_style = "block" *) logic [11:0] rom [0:54271];

    initial begin
        $readmemb("../../rtl/data/crowd1.data", rom);
    end

    always_ff @(posedge clk) begin
        if (addr < 16'd54272) begin   
            crowd1_px <= rom[addr];
        end else begin
            crowd1_px <= '0;
        end
    end

endmodule