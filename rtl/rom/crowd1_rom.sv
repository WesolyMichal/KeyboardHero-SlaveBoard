module crowd1_rom (
    input  logic clk,
    input  logic [15:0] addr,// address = {addry[7:0], addrx[7:0]}
    output logic [11:0] crowd1_px
);
// image rom content of: crowd1.png
// WIDTH = 256
// HEIGHT = 212
// Format: 0 for black, 1 for white

    (* rom_style = "block" *) logic rom [0:54271];

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