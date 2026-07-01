import game_pkg::*;

module score_counter (
    input  logic        clk,
    input  logic        rst_n,

    // --- WEJŚCIA STERUJĄCE Z GRY ---
    input  game_action  player_action,
    input  logic        action_strobe,
    input  logic        game_active,   // 1 - gra trwa (liczymy punkty), 0 - gra skończona (zamrażamy wynik)

    output logic [15:0] current_score,
    output logic [3:0]  current_multiplier,

    output logic [15:0] end_score
);
    // Parametry
    parameter MAX_MULTIPLIER = 10; // Maksymalny mnożnik
    parameter POINTS_PER_HIT = 10; // Bazowa liczba punktów za jeden HIT
    // Wewnętrzne liczniki
    logic [3:0] consecutive_hits; // Ile HIT-ów z rzędu na obecnym poziomie mnożnika
    logic [3:0] hits_to_next;     // Ile HIT-ów potrzeba, aby zwiększyć mnożnik

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            current_score      <= '0;
            current_multiplier <= 4'd1;
            consecutive_hits   <= '0;
            hits_to_next       <= 4'd4;
            end_score          <= '0;
        end else begin
            if (game_active && action_strobe) begin
                if (player_action == HIT) begin
                    // 1. DODAWANIE PUNKTÓW (baza * obecny mnożnik)
                    current_score <= current_score + (POINTS_PER_HIT * current_multiplier);

                    // 2. LOGIKA MNOŻNIKA
                    if (current_multiplier < MAX_MULTIPLIER) begin
                        if (consecutive_hits + 1 == hits_to_next) begin
                            current_multiplier <= current_multiplier + 1;
                            consecutive_hits   <= '0; // Zerujemy licznik uderzeń
                            hits_to_next       <= 4'd2; // Każdy KROK wyżej wymaga już tylko 2 HIT-ów
                        end else begin
                            // Zwykłe nabijanie combo
                            consecutive_hits <= consecutive_hits + 1;
                        end
                    end else begin
                        // Jeśli jesteśmy na max mnożniku (np. x8), to trzymamy licznik, 
                        // żeby nam się nie przepełnił (nie zrolował)
                        consecutive_hits <= '0;
                    end

                end else if (player_action == MISS) begin
                    // KARA ZA MISS - brutalny powrót do x1
                    current_multiplier <= 4'd1;
                    consecutive_hits   <= '0;
                    hits_to_next       <= 4'd4; // Znów potrzeba 4 HIT-ów do awansu
                end
                
                // Jeśli masz w enumie inne akcje (np. HOLD, RELEASE), 
                // możesz łatwo dopisać kolejne "else if".
            end
            
            // Kopiowanie ostatecznego wyniku na ekran końcowy
            // end_score na bieżąco śledzi wynik, ale gdy game_active spadnie na 0 (koniec piosenki),
            // current_score przestanie rosnąć, więc end_score pięknie zamrozi wynik.
            end_score <= current_score;
        end
    end

endmodule