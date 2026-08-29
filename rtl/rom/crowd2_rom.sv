module crowd2_rom (
    input  logic clk,
    input  logic [15:0] addr, // address = {addry[7:0], addrx[7:0]}
    output logic [11:0] crowd2_px
);
// image rom content of: crowd2.png
// WIDTH = 256
// HEIGHT = 235
// Format: 0 for black, 1 for white

    (* rom_style = "block" *) logic rom [0:60159];

    initial begin
        $readmemb("../../rtl/data/crowd2_bw.data", rom);
    end

    always_ff @(posedge clk) begin
        if ((addr < 16'd60160) && (rom[addr] == 1'b1)) begin
            crowd1_px <= 12'hfff;
        end else begin
            crowd1_px <= '0;
        end
    end

endmodule