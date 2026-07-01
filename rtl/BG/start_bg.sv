import vga_pkg::*;

module start_bg (
    input logic clk,
    input logic rst_n,               // Reset synchroniczny, aktywny stanem niskim
    input logic enter,
    input logic enable_start_in,

    input vga_if vga_in,

    output logic [11:0] rgb_out_start_bg,
    output logic enable_start_out
);

import game_pkg::*;

// --- PARAMETRY --- 
localparam [11:0] BG_COLOR = 12'h3_3_5;
localparam LOGO_X = 0;
localparam LOGO_Y = 640;
localparam LOGO_LENGTH = 48; 
localparam LOGO_WIDTH  = 64; 
localparam LOGO_SCALE = 2; 
localparam LOGO_ADDR_SHIFT = $clog2(LOGO_SCALE);

localparam ENTER_X = 384;
localparam ENTER_Y = 426;
localparam ENTER_LENGTH = 128; 
localparam ENTER_WIDTH  = 64;  
localparam ENTER_SCALE = 2; 
localparam ENTER_ADDR_SHIFT = $clog2(ENTER_SCALE);

localparam TEXT_X = 96;
localparam TEXT_Y = 200;
localparam TEXT_LENGTH = 13; 
localparam TEXT_WIDTH  = TEXT_LENGTH * 8;
localparam TEXT_HEIGHT = 16;
localparam TEXT_SCALE = 8; 
localparam TEXT_ADDR_SHIFT = $clog2(TEXT_SCALE);

localparam logic [0:TEXT_LENGTH-1] [7:0] TEXT = "Keyboard-Hero";

// --- SYGNAŁY WEWNĘTRZNE ---
logic [11:0] rgb_nxt;

logic [6:0] voff_text;
logic [7:0] hoff_text;
logic [7:0] char_code;
logic [2:0] px_h_in_char;

// Rejestry potoku (Pipeline) do synchronizacji z opóźnieniem pamięci ROM (2 cykle opóźnienia)
logic d1_vblnk, d2_vblnk;
logic d1_hblnk, d2_hblnk;
logic in_logo, d1_in_logo, d2_in_logo;
logic in_button, d1_in_button, d2_in_button;
logic in_text, d1_in_text, d2_in_text;
logic [2:0] d1_px_h_in_char, d2_px_h_in_char;
logic d1_enter, d2_enter;

logic [1:0] enable_reg;

// Adresy dla pamięci ROM
logic [11:0] logo_addr_nxt, logo_addr;
logic [12:0] enter_addr_nxt, enter_addr;
logic [10:0] font_addr_nxt, font_addr;

// Wyjścia z pamięci ROM
logic [11:0] logo_rgb;
logic        enter_bit;
logic [7:0]  font_pixels;

// --- INSTANCJE ROM ---
agh_image_rom u_agh_image_rom (
    .clk,
    // .rst_n, 
    .address(logo_addr),
    .rgb(logo_rgb)
);

enter_button_rom u_enter_button_rom  (
     .clk,
    //  .rst_n,
     .rom_addr(enter_addr),
     .enter_pixel_bit(enter_bit)
 );

 font_rom u_font_rom (
    .clk,
    // .rst_n,
    .addr(font_addr),
    .char_line_pixels(font_pixels)
 );


// --- CYKL 0: Logika kombinacyjna wyliczania adresów i flag ---
always_comb begin
    logo_addr_nxt  = '0;
    enter_addr_nxt = '0;
    font_addr_nxt  = '0;
    
    in_logo   = 1'b0;
    in_button = 1'b0;
    in_text   = 1'b0;
    
    char_code    = '0;
    px_h_in_char = '0;

    // Logika ENTER
    if ((vga_in.hcount >= ENTER_X && vga_in.vcount >= ENTER_Y) && 
        (vga_in.hcount < ENTER_X + (ENTER_LENGTH * ENTER_SCALE) && vga_in.vcount < ENTER_Y + (ENTER_WIDTH * ENTER_SCALE))) begin
        in_button = 1'b1;
        enter_addr_nxt = { 6'((vga_in.vcount - ENTER_Y) >> ENTER_ADDR_SHIFT), 7'((vga_in.hcount - ENTER_X) >> ENTER_ADDR_SHIFT) };
    end

    // Logika LOGO
    if ((vga_in.hcount >= LOGO_X && vga_in.vcount >= LOGO_Y) && 
        (vga_in.hcount < LOGO_X + (LOGO_LENGTH * LOGO_SCALE) && vga_in.vcount < LOGO_Y + (LOGO_WIDTH * LOGO_SCALE))) begin
        in_logo = 1'b1;
        logo_addr_nxt = { 6'((vga_in.vcount - LOGO_Y) >> LOGO_ADDR_SHIFT), 6'((vga_in.hcount - LOGO_X) >> LOGO_ADDR_SHIFT) };
    end

    // Logika TEXT
    if ((vga_in.hcount >= TEXT_X && vga_in.hcount < TEXT_X + (TEXT_WIDTH << TEXT_ADDR_SHIFT)) && 
        (vga_in.vcount >= TEXT_Y && vga_in.vcount < TEXT_Y + (TEXT_HEIGHT << TEXT_ADDR_SHIFT))) begin
        in_text = 1'b1;
        hoff_text = (vga_in.hcount - TEXT_X) >> TEXT_ADDR_SHIFT;
        voff_text = (vga_in.vcount - TEXT_Y) >> TEXT_ADDR_SHIFT;
    
        char_code = TEXT[ hoff_text / 8 ]; 
        font_addr_nxt = { char_code[6:0], 4'(voff_text[3:0]) };
        px_h_in_char = hoff_text[2:0];
    end
end


// --- CYKL 1: Rejestracja adresów ROM oraz pierwszy stopień opóźnień ---
always_ff @(posedge clk) begin
    if (!rst_n) begin
        logo_addr       <= '0;
        enter_addr      <= '0;
        font_addr       <= '0;
        
        d1_vblnk        <= 1'b0;
        d1_hblnk        <= 1'b0;
        d1_in_logo      <= 1'b0;
        d1_in_button    <= 1'b0;
        d1_in_text      <= 1'b0;
        d1_px_h_in_char <= '0;
        d1_enter        <= 1'b0;
    end else begin
        logo_addr       <= logo_addr_nxt;
        enter_addr      <= enter_addr_nxt;
        font_addr       <= font_addr_nxt;
        
        d1_vblnk        <= vga_in.vblnk;
        d1_hblnk        <= vga_in.hblnk;
        d1_in_logo      <= in_logo;
        d1_in_button    <= in_button;
        d1_in_text      <= in_text;
        d1_px_h_in_char <= px_h_in_char;
        d1_enter        <= enter;
    end
end


// --- CYKL 2: Drugi stopień opóźnień ---
always_ff @(posedge clk) begin
    if (!rst_n) begin
        d2_vblnk        <= 1'b0;
        d2_hblnk        <= 1'b0;
        d2_in_logo      <= 1'b0;
        d2_in_button    <= 1'b0;
        d2_in_text      <= 1'b0;
        d2_px_h_in_char <= '0;
        d2_enter        <= 1'b0;
    end else begin
        d2_vblnk        <= d1_vblnk;
        d2_hblnk        <= d1_hblnk;
        d2_in_logo      <= d1_in_logo;
        d2_in_button    <= d1_in_button;
        d2_in_text      <= d1_in_text;
        d2_px_h_in_char <= d1_px_h_in_char;
        d2_enter        <= d1_enter;
    end
end


// --- Łączenie kolorów (Cykl 2) ---
always_comb begin
    if (d2_hblnk || d2_vblnk || !enable_reg[1]) begin 
        rgb_nxt = 12'h000;
    end else if (d2_in_logo) begin 
        rgb_nxt = logo_rgb;
    end else if (d2_in_button) begin 
        rgb_nxt = enter_bit ? 12'hf_f_f : 12'h0_0_0;
        if (d2_enter)
            rgb_nxt = ~rgb_nxt;
    end else if (d2_in_text && font_pixels[~d2_px_h_in_char]) begin 
        rgb_nxt = 12'hf_f_0;
    end else begin  
        rgb_nxt = BG_COLOR;
    end
end


// --- Wyjściowy rejestr ---
always_ff @(posedge clk) begin
    if (!rst_n) begin
        rgb_out_start_bg <= '0;
        enable_reg       <= '0;
        enable_start_out <= 1'b0;
    end else begin
        rgb_out_start_bg <= rgb_nxt;
        enable_reg       <= {enable_reg[0], enable_start_in}; 
        enable_start_out <= enable_reg[1];
    end
end

endmodule