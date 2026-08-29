import vga_pkg::*;

module endscreen_bg (
    input logic clk,
    input logic rst_n,
    input logic [15:0] end_score_in,
    input logic enable_endscreen_in,

    input vga_if vga_in,

    output logic [11:0] rgb_out_endscreen_bg,
    output logic enable_endscreen_out
);

// --- PARAMETRY --- 
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

// Flagi kombinacyjne
logic in_text, in_star, in_score, star_is_earned;

// Rejestry opóźniające
logic [1:0] vblnk_reg, hblnk_reg;
logic [1:0] in_text_reg, in_star_reg, star_is_earned_reg, in_score_reg;
logic [5:0] px_h_in_char_reg;
logic [1:0] enable_reg;

// Sygnały dla pamięci ROM
logic [10:0] font_addr, font_addr_nxt;
logic [7:0]  font_pixels;

logic [12:0] star_addr, star_addr_nxt;
logic [1:0]  star_pixel;

logic [10:0] brickwall_x, brickwall_y;
logic [17:0] brickwall_addr_nxt, brickwall_addr;
logic [11:0] brickwall_pixels;

function automatic logic [10:0] wrap_coordinate(
    input logic [10:0] coordinate,
    input logic [10:0] dimension
);
    wrap_coordinate = (coordinate >= dimension) ? coordinate - dimension : coordinate;
endfunction

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

brickwall u_brickwall_rom (
    .clk,
    .addr(brickwall_addr),
    .brickwall_px(brickwall_pixels)
 );


// --- Logika kombinacyjna wyliczania adresów i flag ---
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

    brickwall_addr_nxt = '0;

    brickwall_x = wrap_coordinate(vga_in.hcount, 11'd600);
    brickwall_y = wrap_coordinate(vga_in.vcount, 11'd274);
    brickwall_y = wrap_coordinate(brickwall_y, 11'd274);
    brickwall_addr_nxt = (brickwall_y * 17'd600) + brickwall_x;

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
            8'd0: current_digit = digit_3;
            8'd1: current_digit = digit_2;
            8'd2: current_digit = digit_1;
            8'd3: current_digit = digit_0;
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
            star_addr_nxt = (voff_star << 1) + (voff_star << 4) + (voff_star << 5);
            star_addr_nxt += px_in_star; 

            if (star_idx == 0 && end_score >= 200) star_is_earned = 1'b1;
            if (star_idx == 1 && end_score >= 400) star_is_earned = 1'b1;
            if (star_idx == 2 && end_score >= 600) star_is_earned = 1'b1;
        end
    end
end


// --- Rejestracja danych ---
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        font_addr         <= '0;
        star_addr         <= '0;
        brickwall_addr    <= '0;

        end_score         <= '0;
        digit_3           <= '0;
        digit_2           <= '0;
        digit_1           <= '0;
        digit_0           <= '0;

        enable_reg        <= '0;
        
        vblnk_reg           <= 2'b0;
        hblnk_reg           <= 2'b0;
        in_text_reg         <= 2'b0;
        in_star_reg         <= 2'b0; 
        in_score_reg        <= 2'b0;
        px_h_in_char_reg    <= '0;
        star_is_earned_reg  <= 2'b0;  
    end else begin
        font_addr         <= font_addr_nxt;
        star_addr         <= star_addr_nxt;
        brickwall_addr    <= brickwall_addr_nxt;
        
        end_score         <= end_score_in; 
        digit_3           <= (end_score_in / 1000) % 10; 
        digit_2           <= (end_score_in / 100) % 10;  
        digit_1           <= (end_score_in / 10) % 10;   
        digit_0           <= end_score_in % 10;          

        enable_reg        <= {enable_reg[0], enable_endscreen_in};
        vblnk_reg           <= {vblnk_reg[0], vga_in.vblnk};
        hblnk_reg           <= {hblnk_reg[0], vga_in.hblnk};
        in_text_reg         <= {in_text_reg[0], in_text};
        in_star_reg         <= {in_star_reg[0], in_star}; 
        in_score_reg        <= {in_score_reg[0], in_score};
        px_h_in_char_reg    <= {px_h_in_char_reg[2:0], px_h_in_char};
        star_is_earned_reg  <= {star_is_earned_reg[0], star_is_earned}; 
    end
end

// --- Łączenie kolorów ---
always_comb begin
    if (hblnk_reg[1] || vblnk_reg[1] || !enable_reg[1]) begin 
        rgb_nxt = 12'h000;
        
    end else if ((in_text_reg[1] || in_score_reg[1]) && font_pixels[~px_h_in_char_reg[5:3]]) begin
        rgb_nxt = 12'hf_f_0;

    end else if (in_star_reg[1]) begin
        case (star_pixel)
            2'b00: rgb_nxt = brickwall_pixels;
            2'b01: rgb_nxt = 12'hf_f_f; 
            2'b10: begin
                if (star_is_earned_reg[1])
                    rgb_nxt = 12'hf_f_0; 
                else 
                    rgb_nxt = 12'h3_3_3; 
            end
            default: rgb_nxt = brickwall_pixels;
        endcase     
    end else begin  
        rgb_nxt = brickwall_pixels;
    end
end


// --- Wyjściowy rejestr ---
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rgb_out_endscreen_bg <= '0;
        enable_endscreen_out <= 1'b0;
    end else begin
        enable_endscreen_out <= enable_reg[1];
        rgb_out_endscreen_bg <= rgb_nxt;
    end
end

endmodule