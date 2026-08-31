/*
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Jakub Suder
 *
 * Description:
 * Creates on song_bg value of current score and multiplier.
 */
import vga_pkg::*;

module score_mask (
    input logic clk,
    input logic rst_n,

    input vga_if  vga_in,
    output vga_if vga_out,

    input logic enable_in,
    output logic enable_out,

    input logic [23:0] current_score,
    input logic [3:0]  current_multiplier
);
// --- PARAMETRY --- 
localparam [11:0] TEXT_COLOR = 12'hf00; 
localparam TEXT_SCALE = 2; 
localparam TEXT_ADDR_SHIFT = $clog2(TEXT_SCALE);

// SCORE
localparam SCORE_X = 32;
localparam SCORE_Y = 32;
localparam SCORE_CHARS = 15; 
localparam SCORE_WIDTH = SCORE_CHARS * 8;
localparam SCORE_HEIGHT = 16;

// MULTIPLIER
localparam MULTI_X = 32;
localparam MULTI_Y = 70; 
localparam MULTI_CHARS = 10; 
localparam MULTI_WIDTH = MULTI_CHARS * 8;
localparam MULTI_HEIGHT = 16;

// PRZEDROSTKI
localparam logic [0:6][7:0] STR_SCORE = "Score: ";
localparam logic [0:7][7:0] STR_MULTI = "Multi: x";

// --- SYGNAŁY WEWNĘTRZNE ---
logic [3:0] s_5, s_4, s_3, s_2, s_1, s_0;
logic [23:0] bcd_score;
logic [3:0] m_1, m_0;

logic [11:0] rgb_nxt;
logic [1:0]  enable_reg;

logic [15:0] hoff_text, voff_text;
logic [7:0]  char_code;
logic [3:0]  char_idx; 
logic [2:0]  px_h_in_char, d1_px_h_in_char;

logic in_score, d1_in_score;
logic in_multi, d1_in_multi;

logic [10:0] font_addr;
logic [7:0]  font_pixels;

// Funkcja konwertująca system binarny na BCD kożystając z algorytmu Double Dabble
function automatic logic [23:0] bin_to_bcd(input logic [23:0] bin);
    logic [23:0] bcd;
    bcd = '0;
    
    for (int i = 23; i >= 0; i--) begin
        if (bcd[3:0]   >= 5) bcd[3:0]   = bcd[3:0]   + 3;
        if (bcd[7:4]   >= 5) bcd[7:4]   = bcd[7:4]   + 3;
        if (bcd[11:8]  >= 5) bcd[11:8]  = bcd[11:8]  + 3;
        if (bcd[15:12] >= 5) bcd[15:12] = bcd[15:12] + 3;
        if (bcd[19:16] >= 5) bcd[19:16] = bcd[19:16] + 3;
        if (bcd[23:20] >= 5) bcd[23:20] = bcd[23:20] + 3; 

        bcd = {bcd[22:0], bin[i]};
    end
    
    return bcd;
endfunction

// OPÓŹNIONE SYGNAŁY Z INTERFEJSU VGA
vga_if d1;

// --- MODUŁ OPÓŹNIAJĄCY ---
delay #(
    .WIDTH(38), 
    .CLK_DEL(1)
) u_vga_in_del1 (
    .clk(clk),
    .rst_n(rst_n),
    .din(vga_in),
    .dout(d1)
);

// --- INSTANCJA FONT ROM ---
font_rom u_font_rom (
    .clk(clk),
    .addr(font_addr),
    .char_line_pixels(font_pixels)
);

// --- LOGIKA POZYCJI, ZNAKÓW I WYLICZEŃ ---
always_comb begin   
    in_score     = 1'b0;
    in_multi     = 1'b0;
    font_addr    = '0;
    char_code    = 8'h20; 
    hoff_text    = '0;
    voff_text    = '0;
    px_h_in_char = '0;
    char_idx     = '0;

    bcd_score = bin_to_bcd(current_score);
    s_5 = bcd_score[23:20];
    s_4 = bcd_score[19:16];
    s_3 = bcd_score[15:12];
    s_2 = bcd_score[11:8];
    s_1 = bcd_score[7:4];
    s_0 = bcd_score[3:0];

    m_1 = (current_multiplier / 10) % 10;
    m_0 = current_multiplier % 10;

    // SCORE
    if ((vga_in.hcount >= SCORE_X && vga_in.hcount < SCORE_X + (SCORE_WIDTH << TEXT_ADDR_SHIFT)) && 
        (vga_in.vcount >= SCORE_Y && vga_in.vcount < SCORE_Y + (SCORE_HEIGHT << TEXT_ADDR_SHIFT))) begin
        
        in_score = 1'b1;
        hoff_text = (vga_in.hcount - SCORE_X) >> TEXT_ADDR_SHIFT;
        voff_text = (vga_in.vcount - SCORE_Y) >> TEXT_ADDR_SHIFT;
        
        char_idx = (hoff_text >> 3);
        
        if (char_idx < 7) char_code = STR_SCORE[char_idx];
        else if (char_idx == 7) char_code = 8'h30 + s_5;
        else if (char_idx == 8) char_code = 8'h30 + s_4;
        else if (char_idx == 9) char_code = 8'h30 + s_3;
        else if (char_idx == 10) char_code = 8'h30 + s_2;
        else if (char_idx == 11) char_code = 8'h30 + s_1;
        else char_code = 8'h30 + s_0;

        font_addr = {char_code[6:0], 4'(voff_text[3:0])};
        px_h_in_char = hoff_text[2:0];

    // MULTIPLIER
    end else if ((vga_in.hcount >= MULTI_X && vga_in.hcount < MULTI_X + (MULTI_WIDTH << TEXT_ADDR_SHIFT)) && 
                 (vga_in.vcount >= MULTI_Y && vga_in.vcount < MULTI_Y + (MULTI_HEIGHT << TEXT_ADDR_SHIFT))) begin
        
        in_multi = 1'b1;
        hoff_text = (vga_in.hcount - MULTI_X) >> TEXT_ADDR_SHIFT;
        voff_text = (vga_in.vcount - MULTI_Y) >> TEXT_ADDR_SHIFT;
        char_idx = hoff_text >> 3;

        if (char_idx < 8) char_code = STR_MULTI[char_idx];
        else if (char_idx == 8) char_code = 8'h30 + m_1;
        else char_code = 8'h30 + m_0;

        font_addr = {char_code[6:0], 4'(voff_text[3:0])};
        px_h_in_char = hoff_text[2:0];
    end
end

// --- SYNCHRONIZACJA FLAG  ---
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        d1_in_score     <= 1'b0;
        d1_in_multi     <= 1'b0;
        d1_px_h_in_char <= '0;
    end else begin
        d1_in_score     <= in_score;
        d1_in_multi     <= in_multi;
        d1_px_h_in_char <= px_h_in_char;
    end
end

// --- ŁĄCZENIE KOLORÓW ---
always_comb begin
    rgb_nxt = d1.rgb;

    if(d1.hblnk || d1.vblnk) begin
        rgb_nxt = 12'h0_0_0;
        
    end else if (enable_reg[0]) begin
        if((d1_in_score || d1_in_multi) && font_pixels[~d1_px_h_in_char]) begin
            rgb_nxt = TEXT_COLOR; 
        end             
    end
end

// --- WYJŚCIOWY REJESTR ---
always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        vga_out.vcount   <= '0;
        vga_out.hcount   <= '0;
        vga_out.vsync    <= '0;
        vga_out.hsync    <= '0;
        vga_out.vblnk    <= '0;
        vga_out.hblnk    <= '0;
        vga_out.rgb      <= '0;

        enable_reg       <= '0;
        enable_out       <= '0;
    end else begin
        enable_reg       <= {enable_reg[0], enable_in}; 
        enable_out       <= enable_reg[1];

        vga_out.vcount   <= d1.vcount;
        vga_out.hcount   <= d1.hcount;
        vga_out.vsync    <= d1.vsync;
        vga_out.hsync    <= d1.hsync;
        vga_out.vblnk    <= d1.vblnk;
        vga_out.hblnk    <= d1.hblnk;
        
        vga_out.rgb      <= rgb_nxt;
    end
end

endmodule