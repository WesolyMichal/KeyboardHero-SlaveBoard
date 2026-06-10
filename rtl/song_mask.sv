import game_pkg::*;

module song_mask (
    input logic clk,
    input logic rst_n,

    vga_if.in vga_in,
    output logic [11:0] rgb_out_mask,

    input logic enable_mask_in,
    input logic [1:0] song_select // Input to select the song from ROM
);

// --- PARAMETRY KOLORÓW PRZYCISKÓW ---
localparam [11:0] COLOUR_RED     = 12'hf_0_0;
localparam [11:0] COLOUR_GREEN   = 12'h0_f_0;
localparam [11:0] COLOUR_BLUE    = 12'h0_0_f;
localparam [11:0] COLOUR_YELLOW  = 12'hf_f_0;
localparam [11:0] COLOUR_MAGENTA = 12'hf_0_f;
localparam [11:0] COLOUR_CYAN    = 12'h0_f_f;

localparam [11:0] HIT_LINE_COLOR = 12'h0_0_0; // Czarna

// --- PARAMETRY GRYFU ---
localparam NECK_X      = 384;
localparam NECK_Y      = 0;
localparam NECK_WIDTH  = 256;

// --- PARAMETRY PRZYCISKÓW (6 Buttonów) ---
// Każdy button ma ~42px szerokości (256 / 6 = 42.67)
localparam BUTTON_WIDTH  = 42;
localparam BUTTON_COUNT  = 6;

// Hit line na Y=120
localparam HIT_LINE_Y = 120;
localparam HIT_LINE_HEIGHT = 2; // Grubość linii w pikselach

// Obszar, gdzie mogą się pojawiać nuty i feedback (od Y=0 do hit line)
localparam ACTIVE_ZONE_START = NECK_Y;        // Y=0
localparam ACTIVE_ZONE_END   = HIT_LINE_Y;    // Y=120

// --- PARAMETRY OPADAJĄCYCH NUT (WCZYTYWANE Z PLIKU) ---
localparam NOTE_COUNT       = 6;
localparam NOTE_BASE_HEIGHT = 20;          // Podstawowa wysokość nuty, będzie mnożona przez `duration`
localparam NOTE_SPEED       = 2;          // Piksele na klatkę (szybciej = bardziej dynamiczna gra)
localparam signed NOTE_SPAWN_Y = -40;      // Pozycja Y, na której pojawia się nowa nuta
localparam SONG_END_Y       = 720;        // Pozycja Y, za którą nuta znika

// --- PARAMETRY PULI NUT ---
localparam MAX_ACTIVE_NOTES = 32; // Maksymalna liczba nut na ekranie jednocześnie

// --- SYGNAŁY WEWNĘTRZNE ---
logic [11:0] rgb_nxt;
logic [1:0] enable_reg;

// Flagi kombinacyjne
logic in_button[BUTTON_COUNT-1:0];
logic in_hit_line;
logic in_note[NOTE_COUNT-1:0];

// Flagi opóźnione
logic d1_in_button[BUTTON_COUNT-1:0];
logic d1_in_hit_line;
logic d1_in_note[NOTE_COUNT-1:0];

logic d1_vblnk, d1_hblnk;
logic frame_tick;

// --- STAN GRY ---
logic [7:0] note_addr; // Adres nuty do wczytania z ROMu (song_rom używa [7:0])
note_t current_note;   // Nuta wczytana z ROMu
logic [15:0] wait_timer; // Licznik klatek do następnego zdarzenia z nutą

// Struktura opisująca pojedynczą, aktywną nutę na ekranie
typedef struct {
    logic active;
    logic [2:0] track;
    logic signed [15:0] y_pos;
    logic [15:0] height;
} active_note_t;

// Pula aktywnych nut
active_note_t active_notes[MAX_ACTIVE_NOTES-1:0];

song_rom u_song_rom (
    .clk(clk),
    .song_select(song_select),
    .note_addr(note_addr),
    .note(current_note)
);

// Sygnały opóźnione z modułu delay

// --- MODUŁ OPÓŹNIAJĄCY ---
delay #(
    .WIDTH(2),
    .CLK_DEL(1)
) u_vga_in_del1 (
    .clk,
    .rst_n,
    .din({vga_in.vblnk, vga_in.hblnk}),
    .dout({d1_vblnk, d1_hblnk})
);

// --- LOGIKA POZYCJI (Cykl 0) ---
always_comb begin
    // Resetujemy wszystkie flagi
    for (int i = 0; i < BUTTON_COUNT; i++) begin
        in_button[i] = 1'b0;
        in_note[i] = 1'b0;
    end
    in_hit_line = 1'b0;

    // Sprawdzamy Hit Line (pozioma czarna linia)
    if (vga_in.vcount >= HIT_LINE_Y && 
        vga_in.vcount < HIT_LINE_Y + HIT_LINE_HEIGHT &&
        vga_in.hcount >= NECK_X && 
        vga_in.hcount < NECK_X + NECK_WIDTH) begin
        in_hit_line = 1'b1;
    end

    // Sprawdzamy każdy z 6 przycisków (kolumny gryfu)
    for (int i = 0; i < BUTTON_COUNT; i++) begin
        if (vga_in.hcount >= NECK_X + (BUTTON_WIDTH * i) &&
            vga_in.hcount < NECK_X + (BUTTON_WIDTH * i) + BUTTON_WIDTH &&
            vga_in.vcount >= ACTIVE_ZONE_START &&
            vga_in.vcount < ACTIVE_ZONE_END) begin
            in_button[i] = 1'b1;
        end
    end

    // Sprawdzamy opadające nuty
    // Przechodzimy przez całą pulę aktywnych nut
    for (int i = 0; i < MAX_ACTIVE_NOTES; i++) begin
        if (active_notes[i].active) begin
            logic [2:0] track = active_notes[i].track;
            if (active_notes[i].y_pos >= 0 && // Rysuj tylko widoczną część
                vga_in.vcount >= active_notes[i].y_pos &&
                vga_in.vcount < active_notes[i].y_pos + active_notes[i].height &&
                vga_in.hcount >= NECK_X + (BUTTON_WIDTH * track) &&
                vga_in.hcount < NECK_X + (BUTTON_WIDTH * track) + BUTTON_WIDTH) begin
                in_note[track] = 1'b1;
            end
        end
    end
end

// --- SYNCHRONIZACJA FLAG (Cykl 1) ---
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        d1_in_hit_line <= 1'b0;
        frame_tick     <= 1'b0;
        note_addr      <= '0;
        wait_timer     <= 100; // Początkowe opóźnienie przed pierwszą nutą
        for (int i = 0; i < MAX_ACTIVE_NOTES; i++) begin
            active_notes[i].active <= 1'b0;
        end
        for (int i = 0; i < NOTE_COUNT; i++) begin
            d1_in_button[i] <= 1'b0;
            d1_in_note[i]   <= 1'b0;
        end
    end else begin
        // Opóźnianie sygnałów rysowania o 1 cykl
        d1_in_hit_line <= in_hit_line;
        for (int i = 0; i < BUTTON_COUNT; i++) begin
            d1_in_button[i] <= in_button[i];
            d1_in_note[i]   <= in_note[i];
        end

        // Logika aktualizowana raz na klatkę
        frame_tick <= (vga_in.hcount == 0 && vga_in.vcount == 0);
        if (frame_tick) begin
            // --- Spawner nut ---
            if (wait_timer > 0) begin
                wait_timer <= wait_timer - 1;
            end else begin 
                wait_timer <= current_note.waiting;
                note_addr <= note_addr + 1;

                // Dla każdego przycisku w masce, znajdź wolny slot w puli i aktywuj nutę
                for (int i = 0; i < NOTE_COUNT; i++) begin
                    if (current_note.buttons[i]) begin
                        // Znajdź pierwszy wolny slot
                        for (int j = 0; j < MAX_ACTIVE_NOTES; j++) begin
                            if (!active_notes[j].active) begin
                                active_notes[j].active  <= 1'b1;
                                active_notes[j].track   <= i;
                                active_notes[j].y_pos   <= NOTE_SPAWN_Y;
                                active_notes[j].height  <= (current_note.duration > 0 ? current_note.duration : 1) * NOTE_BASE_HEIGHT;
                                break; // Przerwij pętlę, gdy znajdziesz wolny slot
                            end
                        end
                    end
                end
            end

            // --- Przesuwanie nut ---
            for (int i = 0; i < MAX_ACTIVE_NOTES; i++) begin
                if (active_notes[i].active) begin
                    if (active_notes[i].y_pos >= SONG_END_Y) begin
                        active_notes[i].active <= 1'b0; // Deaktywuj nutę, zwalniając slot
                    end else begin
                        active_notes[i].y_pos <= active_notes[i].y_pos + NOTE_SPEED;
                    end
                end
            end
        end
    end
end

// --- ŁĄCZENIE KOLORÓW (MULTIPLEKSER) ---
always_comb begin
    // Domyślnie przezroczyste (nie rysujemy nic)
    if (d1_hblnk || d1_vblnk || !enable_reg[0]) begin
        rgb_nxt = 12'h0_0_0;
    end else begin
        // Nuty mają pierwszeństwo nad kolumnami i linią
        if (d1_in_note[0]) begin
            rgb_nxt = COLOUR_RED;
        end else if (d1_in_note[1]) begin
            rgb_nxt = COLOUR_GREEN;
        end else if (d1_in_note[2]) begin
            rgb_nxt = COLOUR_BLUE;
        end else if (d1_in_note[3]) begin
            rgb_nxt = COLOUR_YELLOW;
        end else if (d1_in_note[4]) begin
            rgb_nxt = COLOUR_MAGENTA;
        end else if (d1_in_note[5]) begin
            rgb_nxt = COLOUR_CYAN;
        end else if (d1_in_hit_line) begin
            rgb_nxt = HIT_LINE_COLOR;
        end else if (d1_in_button[0]) begin
            rgb_nxt = COLOUR_RED;
        end else if (d1_in_button[1]) begin
            rgb_nxt = COLOUR_GREEN;
        end else if (d1_in_button[2]) begin
            rgb_nxt = COLOUR_BLUE;
        end else if (d1_in_button[3]) begin
            rgb_nxt = COLOUR_YELLOW;
        end else if (d1_in_button[4]) begin
            rgb_nxt = COLOUR_MAGENTA;
        end else if (d1_in_button[5]) begin
            rgb_nxt = COLOUR_CYAN;
        end else begin
            rgb_nxt = 12'h0_0_0;
        end
    end
end

// --- WYJŚCIOWY REJESTR ---
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        rgb_out_mask <= '0;
        enable_reg <= '0;
    end else begin
        enable_reg <= {enable_reg[0], enable_mask_in};
        rgb_out_mask <= rgb_nxt;
    end
end

endmodule
