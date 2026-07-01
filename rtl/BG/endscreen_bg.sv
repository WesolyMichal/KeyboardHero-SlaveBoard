import vga_pkg::*;

module endscreen_bg (
    input logic clk,
    input logic rst_n,               // Reset synchroniczny, aktywny stanem niskim
    input logic [15:0] end_score_in,
    input logic enable_endscreen_in,

    input vga_if vga_in,

    output logic [11:0] rgb_out_endscreen_bg,
    output logic enable_endscreen_out
);

// --- PARAMETRY --- 
localparam [11:0] BG_COLOR = 12'h3_3_5;

localparam TEXT_X = 160;
localparam TEXT_Y = 200;
localparam TEXT_LENGTH = 11; 
localparam TEXT_WIDTH  = TEXT_LENGTH * 8;
localparam TEXT_HEIGHT = 16;
localparam TEXT_SCALE = 8; 
localparam TEXT_ADDR_SHIFT = $clog2(TEXT_SCALE);

localparam logic [0:TEXT_LENGTH-1] [7:0] TEXT = "Your score:";

localparam SCORE_X = 384;
localparam SCORE_Y = 340; 
localparam SCORE_LENGTH = 4; 
localparam SCORE_WIDTH  = SCORE_LENGTH * 8;

localparam STAR_X = 362;
localparam STAR_Y = 468;
localparam STAR_LENGTH = 50;
localparam STAR_GAP = 6;
localparam STAR_NR = 3;
localparam TILE_WIDTH = STAR_LENGTH + STAR_GAP;
localparam STARS_LENGTH = (TILE_WIDTH * STAR_NR) - STAR_GAP;
localparam STAR_SCALE = 2; 
localparam STAR_ADDR_SHIFT = $clog2(STAR_SCALE);

// --- SYGNAŁY WEWNĘTRZNE ---
logic [11:0] rgb_nxt;
logic [15:0] end_score;

logic [6:0] voff_text;
logic [7:0] hoff_text;
logic [7:0] char_code;
logic [2:0] px_h_in_char;

logic [9:0] voff_star;
logic [9:0] hoff_star;
logic [STAR_NR-1 :0] star_idx;
logic [9:0] px_in_star;

logic [6:0] voff_score;
logic [7:0] hoff_score;
logic [3:0] digit_3, digit_2, digit_1, digit_0;
logic [3:0] current_digit;

logic [1:0] enable_reg;

// Flagi kombinacyjne (Cykl 0)
logic in_text;
logic in_star; 
logic star_is_earned;
logic in_score;

// Rejestry potoku (Pipeline) dla zachowania opóźnienia 3 taktów
logic d1_vblnk, d2_vblnk;
logic d1_hblnk, d2_hblnk;
logic d1_in_text, d2_in_text;
logic d1_in_star, d2_in_star;
logic d1_star_is_earned, d2_star_is_earned;
logic d1_in_score, d2_in_score;
logic [2:0] d1_px_h_in_char, d2_px_h_in_char;

// Pamięci ROM
logic [10:0] font_addr, font_addr_nxt;
logic [7:0]  font_pixels;

logic [12:0] star_addr, star_addr_nxt;
logic [1:0]  star_pixel;

// --- INSTANCJE ROM ---
font_rom u_font_rom (
   .clk(clk),
   .addr(font_addr),
   .char_line_pixels(font_pixels)
);

star_rom u_star_rom (
   .clk(clk),
   .addr(star_addr),
   .star_pixel(star_pixel)   
);


// --- CYKL 0: Logika kombinacyjna wyliczania adresów i flag ---
always_comb begin
    in_text         = 1'b0;
    in_star         = 1'b0; 
    in_score        = 1'b0;
    font_addr_nxt   = '0;
    star_addr_nxt   = '0;
    char_code       = '0;
    px_h_in_char    = '0;
    star_is_earned  = 1'b0;
    current_digit   = 4'd0;

    // Logika TEXT
    if ((vga_in.hcount >= TEXT_X && vga_in.hcount < TEXT_X + (TEXT_WIDTH << TEXT_ADDR_SHIFT)) && 
        (vga_in.vcount >= TEXT_Y && vga_in.vcount < TEXT_Y + (TEXT_HEIGHT << TEXT_ADDR_SHIFT))) begin
        
        in_text       = 1'b1;
        hoff_text     = (vga_in.hcount - TEXT_X) >> TEXT_ADDR_SHIFT;
        voff_text     = (vga_in.vcount - TEXT_Y) >> TEXT_ADDR_SHIFT;
    
        char_code     = TEXT[ hoff_text / 8 ]; 
        font_addr_nxt = { char_code[6:0], 4'(voff_text[3:0]) };
        px_h_in_char  = hoff_text[2:0];

    // Logika SCORE
    end else if ((vga_in.hcount >= SCORE_X && vga_in.hcount < SCORE_X + (SCORE_WIDTH << TEXT_ADDR_SHIFT)) && 
                 (vga_in.vcount >= SCORE_Y && vga_in.vcount < SCORE_Y + (TEXT_HEIGHT << TEXT_ADDR_SHIFT))) begin

        in_score   = 1'b1;
        hoff_score = (vga_in.hcount - SCORE_X) >> TEXT_ADDR_SHIFT;
        voff_score = (vga_in.vcount - SCORE_Y) >> TEXT_ADDR_SHIFT;

        case (hoff_score / 8)
            0: current_digit = digit_3;
            1: current_digit = digit_2;
            2: current_digit = digit_1;
            3: current_digit = digit_0;
            default: current_digit = 4'd0;
        endcase

        char_code     = 8'h30 + current_digit; 
        font_addr_nxt = { char_code[6:0], 4'(voff_score[3:0]) };
        px_h_in_char  = hoff_score[2:0];

    // Logika GWIAZDKI
    end else if (vga_in.hcount >= STAR_X && vga_in.hcount < STAR_X + (STARS_LENGTH << STAR_ADDR_SHIFT) &&
                 vga_in.vcount >= STAR_Y && vga_in.vcount < STAR_Y + (STAR_LENGTH << STAR_ADDR_SHIFT)) begin
                    
        hoff_star  = 10'((vga_in.hcount - STAR_X) >> STAR_ADDR_SHIFT);
        voff_star  = 10'((vga_in.vcount - STAR_Y) >> STAR_ADDR_SHIFT);
        
        star_idx   = hoff_star / TILE_WIDTH;
        px_in_star = hoff_star % TILE_WIDTH;

        if (px_in_star < STAR_LENGTH) begin
            in_star       = 1'b1;
            star_addr_nxt = (voff_star * STAR_LENGTH) + px_in_star; 

            if (star_idx == 0 && end_score >= 200) star_is_earned = 1'b1;
            if (star_idx == 1 && end_score >= 400) star_is_earned = 1'b1;
            if (star_idx == 2 && end_score >= 600) star_is_earned = 1'b1;
        end
    end
end


// --- CYKL 1: Zatrzymywanie potoku i rejestracja danych ---
always_ff @(posedge clk) begin
    // Adresy dla BRAM są poza warunkiem if(!rst_n). 
    // Odcina to asynchroniczny reset z modułu u_timing i eliminuje błąd Vivado.
    if (!rst_n) begin
        end_score         <= '0;
        digit_3           <= '0;
        digit_2           <= '0;
        digit_1           <= '0;
        digit_0           <= '0;

        d1_vblnk          <= 1'b0;
        d1_hblnk          <= 1'b0;
        d1_in_text        <= 1'b0;
        d1_in_star        <= 1'b0; 
        d1_px_h_in_char   <= '0;
        d1_star_is_earned <= 1'b0;
        d1_in_score       <= 1'b0;
        font_addr         <= '0;
        star_addr         <= '0;
    end else begin
        end_score         <= end_score_in; 
        digit_3           <= (end_score_in / 1000) % 10; 
        digit_2           <= (end_score_in / 100) % 10;  
        digit_1           <= (end_score_in / 10) % 10;   
        digit_0           <= end_score_in % 10;          

        d1_vblnk          <= vga_in.vblnk;
        d1_hblnk          <= vga_in.hblnk;
        d1_in_text        <= in_text;
        d1_in_star        <= in_star; 
        d1_px_h_in_char   <= px_h_in_char;
        d1_star_is_earned <= star_is_earned;
        d1_in_score       <= in_score;

        font_addr         <= font_addr_nxt;
        star_addr         <= star_addr_nxt;
    end
end


// --- CYKL 2: Drugi stopień opóźnień ---
always_ff @(posedge clk) begin
    if (!rst_n) begin
        d2_vblnk          <= 1'b0;
        d2_hblnk          <= 1'b0;
        d2_in_text        <= 1'b0;
        d2_in_star        <= 1'b0; 
        d2_px_h_in_char   <= '0;
        d2_star_is_earned <= 1'b0;
        d2_in_score       <= 1'b0;
    end else begin
        d2_vblnk          <= d1_vblnk;
        d2_hblnk          <= d1_hblnk;
        d2_in_text        <= d1_in_text;
        d2_in_star        <= d1_in_star; 
        d2_px_h_in_char   <= d1_px_h_in_char;
        d2_star_is_earned <= d1_star_is_earned;
        d2_in_score       <= d1_in_score;
    end
end


// --- ŁĄCZENIE KOLORÓW (Cykl 2) ---
always_comb begin
    if (d2_hblnk || d2_vblnk || !enable_reg[1]) begin 
        rgb_nxt = 12'h000;
        
    end else if ((d2_in_text || d2_in_score) && font_pixels[~d2_px_h_in_char]) begin
        rgb_nxt = 12'hf_f_0;

    end else if (d2_in_star) begin
        case (star_pixel)
            2'b00: rgb_nxt = BG_COLOR;
            2'b01: rgb_nxt = 12'hf_f_f; 
            2'b10: begin
                if (d2_star_is_earned)
                    rgb_nxt = 12'hf_f_0; 
                else 
                    rgb_nxt = 12'h3_3_3; 
            end
            default: rgb_nxt = BG_COLOR;
        endcase     
    end else begin  
        rgb_nxt = BG_COLOR;
    end
end


// --- CYKL 3: Wyjściowy rejestr ---
always_ff @(posedge clk) begin
    if (!rst_n) begin
        rgb_out_endscreen_bg <= '0;
        enable_reg           <= '0;
        enable_endscreen_out <= 1'b0;
    end else begin
        enable_reg           <= {enable_reg[0], enable_endscreen_in}; 
        enable_endscreen_out <= enable_reg[1];
        rgb_out_endscreen_bg <= rgb_nxt;
    end
end

endmodule