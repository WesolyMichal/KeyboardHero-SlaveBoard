module mibombo_rom (
    input  logic clk,
    input  logic [15:0] addr,
    output logic mibombo_out
);
    logic [0:0] rom [0:63655];

    initial begin
        $readmemb("../../rtl/data/mibombo.data", rom);
    end

    always_ff @(posedge clk) begin
        if (addr < 63656) begin   
            mibombo_out <= rom[addr];
        end else begin
            mibombo_out <= '0;
        end
    end

endmodule