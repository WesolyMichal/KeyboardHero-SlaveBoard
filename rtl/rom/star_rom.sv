module star_rom (
    input  logic clk,
    input  logic [12:0] addr, // 13 bitów na adresy do 8191
    output logic [1:0] star_pixel
);
    logic [1:0] rom [0:8191]; 

    // Wczytanie pliku przy starcie układu
    initial begin
        $readmemb("../../rtl/data/star.data", rom);
    end

    // Odczyt synchroniczny z opóźnieniem 1 taktu (tak jak prawdzimy Block RAM)
    always_ff @(posedge clk) begin
        star_pixel <= rom[addr];
    end

endmodule