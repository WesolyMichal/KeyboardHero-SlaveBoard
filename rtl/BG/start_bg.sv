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
localparam [11:0] GAME_NAME_COLOR = 12'hf_f_0;
localparam [11:0] AUTHORS_COLOR = 12'hf_f_f;

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

localparam BASE_CHAR_WIDTH = 8;
localparam BASE_CHAR_HEIGHT = 16;

localparam GAME_NAME_X = 96;
localparam GAME_NAME_Y = 200;
localparam GAME_NAME_LENGTH = 13;
localparam GAME_NAME_SCALE = 8;
localparam GAME_NAME_ADDR_SHIFT = $clog2(GAME_NAME_SCALE);
localparam logic [0:GAME_NAME_LENGTH-1] [7:0] GAME_NAME = "Keyboard-Hero";

localparam AUTHORS_X = 190; 
localparam AUTHORS_Y = 720;
localparam AUTHORS_LENGTH = 51;
localparam AUTHORS_SCALE = 2;
localparam AUTHORS_ADDR_SHIFT = $clog2(AUTHORS_SCALE);
localparam logic [0:AUTHORS_LENGTH-1] [7:0] Authors = "GAME DEVELOPED BY MICHAL WESOLOWSKI AND JAKUB SUDER";




// --- SYGNAŁY WEWNĘTRZNE ---
logic [11:0] rgb_nxt;

logic [6:0] voff_game_name;
logic [7:0] hoff_game_name;
logic [7:0] char_code;
logic [2:0] px_h_in_char;
logic [6:0] voff_button;
logic [7:0] hoff_button;
logic [6:0] voff_authors;
logic [8:0] hoff_authors;

// Rejestry potoku (Pipeline) do synchronizacji z opóźnieniem pamięci ROM (2 cykle opóźnienia)
logic d1_vblnk, d2_vblnk;
logic d1_hblnk, d2_hblnk;
logic in_logo, d1_in_logo, d2_in_logo;
logic in_button, d1_in_button, d2_in_button;
logic in_game_name, d1_in_game_name, d2_in_game_name;
logic in_authors, d1_in_authors, d2_in_authors;
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
    in_game_name = 1'b0;
    in_authors = 1'b0;
    
    char_code    = '0;
    px_h_in_char = '0;

    // Logika ENTER
    if ((vga_in.hcount >= ENTER_X && vga_in.vcount >= ENTER_Y) && 
        (vga_in.hcount < ENTER_X + (ENTER_LENGTH * ENTER_SCALE) && vga_in.vcount < ENTER_Y + (ENTER_WIDTH * ENTER_SCALE))) begin
            in_button = 1'b1;
            hoff_button = (vga_in.hcount - ENTER_X) >> ENTER_ADDR_SHIFT;
            voff_button = (vga_in.vcount - ENTER_Y) >> ENTER_ADDR_SHIFT;

            enter_addr_nxt = {voff_button[5:0], hoff_button[6:0]};
    end

    // Logika LOGO
    if ((vga_in.hcount >= LOGO_X && vga_in.vcount >= LOGO_Y) && 
        (vga_in.hcount < LOGO_X + (LOGO_LENGTH * LOGO_SCALE) && vga_in.vcount < LOGO_Y + (LOGO_WIDTH * LOGO_SCALE))) begin
            in_logo = 1'b1;
            logo_addr_nxt = { 6'((vga_in.vcount - LOGO_Y) >> LOGO_ADDR_SHIFT), 6'((vga_in.hcount - LOGO_X) >> LOGO_ADDR_SHIFT) };
    end

    // Logika GAME_NAME
    if ((vga_in.hcount >= GAME_NAME_X && vga_in.hcount < GAME_NAME_X + GAME_NAME_LENGTH * BASE_CHAR_WIDTH * GAME_NAME_SCALE) &&
        (vga_in.vcount >= GAME_NAME_Y && vga_in.vcount < GAME_NAME_Y + BASE_CHAR_HEIGHT * GAME_NAME_SCALE)) begin
            in_game_name = 1'b1;
            hoff_game_name = (vga_in.hcount - GAME_NAME_X) >> GAME_NAME_ADDR_SHIFT;
            voff_game_name = (vga_in.vcount - GAME_NAME_Y) >> GAME_NAME_ADDR_SHIFT;
        
            char_code = GAME_NAME[hoff_game_name / BASE_CHAR_WIDTH];
            font_addr_nxt = { char_code[6:0], 4'(voff_game_name[3:0]) };
            px_h_in_char = hoff_game_name[2:0];
    end

    if ((vga_in.hcount >= AUTHORS_X && vga_in.hcount < AUTHORS_X + AUTHORS_LENGTH * BASE_CHAR_WIDTH * AUTHORS_SCALE) &&
        (vga_in.vcount >= AUTHORS_Y && vga_in.vcount < AUTHORS_Y + BASE_CHAR_HEIGHT * AUTHORS_SCALE)) begin
            in_authors = 1'b1;
            hoff_authors = (vga_in.hcount - AUTHORS_X) >> AUTHORS_ADDR_SHIFT;
            voff_authors = (vga_in.vcount - AUTHORS_Y) >> AUTHORS_ADDR_SHIFT;

            char_code = Authors[hoff_authors >> 3];
            font_addr_nxt = {char_code[6:0], 4'(voff_authors[3:0])};
            px_h_in_char  = hoff_authors[2:0];
    end
end


// --- CYKL 1: Rejestracja adresów ROM oraz pierwszy stopień opóźnień ---
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        logo_addr       <= '0;
        enter_addr      <= '0;
        font_addr       <= '0;
        
        d1_vblnk        <= 1'b0;
        d1_hblnk        <= 1'b0;
        d1_in_logo      <= 1'b0;
        d1_in_button    <= 1'b0;
        d1_in_game_name <= 1'b0;
        d1_in_authors   <= 1'b0;
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
        d1_in_game_name <= in_game_name;
        d1_in_authors   <= in_authors;
        d1_px_h_in_char <= px_h_in_char;
        d1_enter        <= enter;
    end
end


// --- CYKL 2: Drugi stopień opóźnień ---
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d2_vblnk        <= 1'b0;
        d2_hblnk        <= 1'b0;
        d2_in_logo      <= 1'b0;
        d2_in_button    <= 1'b0;
        d2_in_game_name <= 1'b0;
        d2_in_authors   <= 1'b0;
        d2_px_h_in_char <= '0;
        d2_enter        <= 1'b0;
    end else begin
        d2_vblnk        <= d1_vblnk;
        d2_hblnk        <= d1_hblnk;
        d2_in_logo      <= d1_in_logo;
        d2_in_button    <= d1_in_button;
        d2_in_game_name <= d1_in_game_name;
        d2_in_authors   <= d1_in_authors;
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
    end else if (d2_in_game_name && font_pixels[~d2_px_h_in_char]) begin 
        rgb_nxt = GAME_NAME_COLOR;
    end else if (d2_in_authors && font_pixels[~d2_px_h_in_char]) begin 
        rgb_nxt = AUTHORS_COLOR;
    end else begin  
        rgb_nxt = BG_COLOR;
    end
end


// --- Wyjściowy rejestr ---
always_ff @(posedge clk or negedge rst_n) begin
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