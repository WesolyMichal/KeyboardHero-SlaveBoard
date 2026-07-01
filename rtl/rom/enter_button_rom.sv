module enter_button_rom (
    input  logic clk,
    input  logic [12:0] rom_addr, // 13 bitów na adresy do 8191
    output logic enter_pixel_bit
);

    // Deklaracja wewnętrznej pamięci ROM: 1 bit szerokości, 8192 elementów głębokości
    // Zmień 8191 na 4351, jeśli użyjesz dokładnie tego pliku, który wkleiłeś wyżej
    logic [0:0]btn_memory [0:8191]; 

    // Wczytanie pliku przy starcie układu
    initial begin
        // Plik "enter_button.data" musi znajdować się w folderze symulacji 
        // lub być dodany do Vivado jako "Design Source"
        $readmemb("../../rtl/data/enter.data", btn_memory);
    end

    // Odczyt synchroniczny z opóźnieniem 1 taktu (tak jak prawdzimy Block RAM)
    always_ff @(posedge clk) begin
        enter_pixel_bit <= btn_memory[rom_addr];
    end

endmodule