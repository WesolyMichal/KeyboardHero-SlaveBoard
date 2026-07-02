module uart_reader (
    input  logic       clk,
    input  logic       rst_n,
    
    // Połączenia z modułem UART
    input  logic       rx_empty,
    input  logic [7:0] r_data,
    output logic       rd_uart,
    
    // Interfejs wyjściowy
    output logic [7:0] out_data,
    output logic       data_ready
);

    // Definicja stanów jako typ wyliczeniowy (enum) w SystemVerilogu
    typedef enum logic {
        IDLE  = 1'b0,
        READ  = 1'b1
    } state_t;

    state_t state;

    // Blok specyficzny dla przerzutników (always_ff)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            rd_uart    <= 1'b0;
            out_data   <= 8'h00;
            data_ready <= 1'b0;
        end else begin
            // Domyślne wartości dla sygnałów impulsowych
            rd_uart    <= 1'b0;
            data_ready <= 1'b0;

            case (state)
                IDLE: begin
                    if (!rx_empty) begin
                        rd_uart <= 1'b1; // Impuls odczytu z FIFO
                        state   <= READ;
                    end
                end

                READ: begin
                    out_data   <= r_data;     // Zatrzasnij odebrane dane
                    data_ready <= 1'b1;       // Flaga: dane są gotowe
                    state      <= IDLE;
                end
            endcase
        end
    end

endmodule