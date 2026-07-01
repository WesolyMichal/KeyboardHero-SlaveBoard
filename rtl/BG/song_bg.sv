import vga_pkg::*;

module song_bg (
    input logic clk,
    input logic rst_n,               // Reset synchroniczny, aktywny stanem niskim
    input logic enable_song_in,

    input vga_if vga_in,

    output logic [11:0] rgb_out_song_bg,
    output logic enable_song_out
);

// --- PARAMETRY KOLORÓW --- 
localparam [11:0] BG_COLOR   = 12'h3_3_5;
localparam [11:0] NECK_COLOR = 12'h1_1_2; 
localparam [11:0] LINE_COLOR = 12'h8_8_9; 

// Kolory Mibombo
localparam [11:0] MIBOMBO_OUTLINE = 12'hf_f_f;
localparam [11:0] MIBOMBO_INNER   = 12'h7_7_7; 

// --- PARAMETRY GRYFU  ---
localparam NECK_X      = 320; 
localparam NECK_Y      = 0;
localparam NECK_WIDTH  = 384; 
localparam NECK_HEIGHT = 768;

// --- PARAMETRY GŁOŚNIKÓW ---
localparam MIBOMBO_WIDTH  = 218;
localparam MIBOMBO_HEIGHT = 292;
localparam MIBOMBO_Y      = 400; 

localparam MIBOMBO_L_X    = 80;  
localparam MIBOMBO_R_X    = 690; 


// --- SYGNAŁY WEWNĘTRZNE ---
logic [11:0] rgb_nxt;
logic [1:0]  enable_reg;

logic [15:0] hoff_mibombo_l, voff_mibombo_l;
logic [15:0] hoff_mibombo_r, voff_mibombo_r;
logic [15:0] mibombo_addr, mibombo_addr_nxt;
logic        mibombo_pixel; // Zmieniono na logic (w Twoim kodzie porównywałeś mibombo_pixel z 2'b00, podczas gdy rom zwraca 1 bit)

// Flagi kombinacyjne
logic in_neck, in_line;
logic in_mibombo_l, in_mibombo_r;

// Rejestry potoku (Pipeline) dla zachowania opóźnienia 3 taktów
logic d1_vblnk, d2_vblnk;
logic d1_hblnk, d2_hblnk;
logic d1_in_neck, d2_in_neck;
logic d1_in_line, d2_in_line;
logic d1_in_mibombo_l, d2_in_mibombo_l;
logic d1_in_mibombo_r, d2_in_mibombo_r;

// --- ROM DLA GŁOŚNIKA ---
mibombo_rom u_mibombo_rom (
    .clk(clk),
    // .rst_n(rst_n),
    .addr(mibombo_addr),
    .mibombo_out(mibombo_pixel)
);

// --- CYKL 0: Logika kombinacyjna wyliczania adresów i flag ---
always_comb begin
    in_neck        = 1'b0;
    in_line        = 1'b0;
    in_mibombo_l   = 1'b0;
    in_mibombo_r   = 1'b0;
    hoff_mibombo_l = '0;
    voff_mibombo_l = '0;
    hoff_mibombo_r = '0;
    voff_mibombo_r = '0;

    // 1. Logika GRYFU i Linii
    if ((vga_in.hcount >= NECK_X && vga_in.hcount < NECK_X + NECK_WIDTH) && 
        (vga_in.vcount >= NECK_Y && vga_in.vcount < NECK_Y + NECK_HEIGHT)) begin
        
        in_neck = 1'b1;

        if (vga_in.hcount == NECK_X || 
            vga_in.hcount == NECK_X + 64 || 
            vga_in.hcount == NECK_X + 128 || 
            vga_in.hcount == NECK_X + 192 || 
            vga_in.hcount == NECK_X + 256 ||
            vga_in.hcount == NECK_X + 320 ||
            vga_in.hcount == NECK_X + 384 ||
            vga_in.vcount == 640) begin
            
            in_line = 1'b1;
        end
    end

    // 2. Logika MIBOMBO PRAWEGO
    if ((vga_in.hcount >= MIBOMBO_R_X && vga_in.hcount < MIBOMBO_R_X + MIBOMBO_WIDTH) &&
        (vga_in.vcount >= MIBOMBO_Y && vga_in.vcount < MIBOMBO_Y + MIBOMBO_HEIGHT)) begin
        in_mibombo_r   = 1'b1;
        hoff_mibombo_r = 16'(vga_in.hcount - MIBOMBO_R_X);
        voff_mibombo_r = 16'(vga_in.vcount - MIBOMBO_Y);
    end

    // 3. Logika MIBOMBO LEWEGO 
    if ((vga_in.hcount >= MIBOMBO_L_X && vga_in.hcount < MIBOMBO_L_X + MIBOMBO_WIDTH) &&
        (vga_in.vcount >= MIBOMBO_Y && vga_in.vcount < MIBOMBO_Y + MIBOMBO_HEIGHT)) begin
        in_mibombo_l   = 1'b1;
        hoff_mibombo_l = 16'(MIBOMBO_WIDTH - 1 - (vga_in.hcount - MIBOMBO_L_X));
        voff_mibombo_l = 16'(vga_in.vcount - MIBOMBO_Y);
    end

    // Multipleksowanie adresu dla ROMu, aby lewy głośnik nie nadpisywał prawego
    if (in_mibombo_l) begin
        mibombo_addr_nxt = (voff_mibombo_l * MIBOMBO_WIDTH) + hoff_mibombo_l;
    end else if (in_mibombo_r) begin
        mibombo_addr_nxt = (voff_mibombo_r * MIBOMBO_WIDTH) + hoff_mibombo_r;
    end else begin
        mibombo_addr_nxt = '0;
    end
end

// --- CYKL 1: Rejestracja adresu ROM oraz pierwszy stopień opóźnień ---
always_ff @(posedge clk) begin
    if (!rst_n) begin
        mibombo_addr    <= '0;
        d1_vblnk        <= 1'b0;
        d1_hblnk        <= 1'b0;
        d1_in_neck      <= 1'b0;
        d1_in_line      <= 1'b0;
        d1_in_mibombo_l <= 1'b0;
        d1_in_mibombo_r <= 1'b0;
    end else begin
        mibombo_addr    <= mibombo_addr_nxt;
        d1_vblnk        <= vga_in.vblnk;
        d1_hblnk        <= vga_in.hblnk;
        d1_in_neck      <= in_neck;
        d1_in_line      <= in_line;
        d1_in_mibombo_l <= in_mibombo_l;
        d1_in_mibombo_r <= in_mibombo_r;
    end
end

// --- CYKL 2: Drugi stopień opóźnień (Wyrównanie z wyjściem mibombo_rom) ---
always_ff @(posedge clk) begin
    if (!rst_n) begin
        d2_vblnk        <= 1'b0;
        d2_hblnk        <= 1'b0;
        d2_in_neck      <= 1'b0;
        d2_in_line      <= 1'b0;
        d2_in_mibombo_l <= 1'b0;
        d2_in_mibombo_r <= 1'b0;
    end else begin
        d2_vblnk        <= d1_vblnk;
        d2_hblnk        <= d1_hblnk;
        d2_in_neck      <= d1_in_neck;
        d2_in_line      <= d1_in_line;
        d2_in_mibombo_l <= d1_in_mibombo_l;
        d2_in_mibombo_r <= d1_in_mibombo_r;
    end
end

// --- ŁĄCZENIE KOLORÓW (Logika kombinacyjna w Cyklu 2) ---
always_comb begin
    if (d2_hblnk || d2_vblnk || !enable_reg[1]) begin
        rgb_nxt = 12'h000;
        
    // Jeśli z Twojego ROMu wychodzi pojedynczy bit, sprawdź warunek rysowania grafiki:
    end else if ((d2_in_mibombo_l || d2_in_mibombo_r) && mibombo_pixel) begin 
        // Tutaj ustawiłem domyślnie kolor linii obrysowej. 
        // Jeśli mibombo_rom ma zwracać 2-bitowy kolor, zmień typ 'mibombo_pixel' na logic [1:0]
        rgb_nxt = MIBOMBO_OUTLINE; 
        
    end else if (d2_in_line) begin
        rgb_nxt = LINE_COLOR;
        
    end else if (d2_in_neck) begin
        rgb_nxt = NECK_COLOR;
        
    end else begin 
        rgb_nxt = BG_COLOR;
    end
end

// --- CYKL 3: Wyjściowy rejestr ---
always_ff @(posedge clk) begin
    if (!rst_n) begin
        rgb_out_song_bg <= '0;
        enable_reg      <= '0;
        enable_song_out <= '0;
    end else begin
        enable_reg      <= {enable_reg[0], enable_song_in}; 
        enable_song_out <= enable_reg[1];
        rgb_out_song_bg <= rgb_nxt;
    end
end

endmodule