/*
 * Copyright (C) 2026  AGH University of Science and Technology
 * MTM UEC2
 * Author: Jakub Suder
 *
 * Description:
 * This is module responsible for creating backgroud for HOME_SCREEN and WAIT_HOMESCREEN states of slave_FSM.
 */

import vga_pkg::*;
import bg_pkg::*;

module start_bg (
    input logic clk,
    input logic rst_n,
    input logic enter,
    input logic enable_start_in,

    input vga_if vga_in,

    output logic [11:0] rgb_out_start_bg,
    output logic enable_start_out
);

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

// Flagi kombinacyjne
logic in_logo, in_button, in_game_name, in_authors, in_sticker;

// Rejestry opóźniające
logic [1:0] vblnk_reg, hblnk_reg;
logic [1:0] in_logo_reg, in_button_reg, in_game_name_reg, in_authors_reg, in_sticker_reg, enter_reg;
logic [5:0] px_h_in_char_reg;

logic [1:0] enable_reg;

// Sygnały dla pamięci ROM
logic [11:0] logo_addr_nxt, logo_addr;
logic [12:0] enter_addr_nxt, enter_addr;
logic [10:0] font_addr_nxt, font_addr;
logic [17:0] brickwall_addr_nxt, brickwall_addr;
// logic [17:0] sticker_addr_nxt, sticker_addr;
logic [10:0] brickwall_x, brickwall_y;

// Wyjścia z pamięci ROM
logic [11:0] logo_rgb; 
logic        enter_px;
logic [7:0]  font_pixels;
logic [11:0] brickwall_pixels;
//logic [11:0] sticker_pixels;

// --- INSTANCJE ROM ---
agh_image_rom u_agh_image_rom (
    .clk,
    .address(logo_addr),
    .rgb(logo_rgb)
);

enter_button_rom u_enter_button_rom  (
     .clk,
     .rom_addr(enter_addr),
     .enter_px(enter_px)
 );

 font_rom u_font_rom (
    .clk,
    .addr(font_addr),
    .char_line_pixels(font_pixels)
 );

 brickwall_rom u_brickwall_rom (
    .clk,
    .addr(brickwall_addr),
    .brickwall_px(brickwall_pixels)
 );

//  sticker_rom u_sticker_rom (
//     .clk,
//     .addr(sticker_addr),
//     .sticker_px(sticker_pixels)
//  );


// --- Logika kombinacyjna wyliczania adresów i flag ---
always_comb begin
    in_logo   = 1'b0;
    in_button = 1'b0;
    in_game_name = 1'b0;
    in_authors = 1'b0;
    in_sticker = 1'b0;
    logo_addr_nxt  = '0;
    enter_addr_nxt = '0;
    font_addr_nxt  = '0;
    brickwall_addr_nxt = '0;
//   sticker_addr_nxt = '0;
    char_code    = '0;
    px_h_in_char = '0;

    brickwall_x = wrap_coordinate(vga_in.hcount, 11'd600);
    brickwall_y = wrap_coordinate(vga_in.vcount, 11'd274);
    brickwall_y = wrap_coordinate(brickwall_y, 11'd274);
    brickwall_addr_nxt = (brickwall_y * 17'd600) + brickwall_x;

    
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
    // Logika AUTHORS
    if ((vga_in.hcount >= AUTHORS_X && vga_in.hcount < AUTHORS_X + AUTHORS_LENGTH * BASE_CHAR_WIDTH * AUTHORS_SCALE) &&
        (vga_in.vcount >= AUTHORS_Y && vga_in.vcount < AUTHORS_Y + BASE_CHAR_HEIGHT * AUTHORS_SCALE)) begin
            in_authors = 1'b1;
            hoff_authors = (vga_in.hcount - AUTHORS_X) >> AUTHORS_ADDR_SHIFT;
            voff_authors = (vga_in.vcount - AUTHORS_Y) >> AUTHORS_ADDR_SHIFT;

            char_code = Authors[hoff_authors >> 3];
            font_addr_nxt = {char_code[6:0], 4'(voff_authors[3:0])};
            px_h_in_char  = hoff_authors[2:0];
    end
    // Logika STICKER
    // if ((vga_in.hcount >= STICKER_X && vga_in.hcount < STICKER_X + STICKER_LENGTH) &&
    //     (vga_in.vcount >= STICKER_Y && vga_in.vcount < STICKER_Y + STICKER_WIDTH )) begin
    //         in_sticker = 1'b1;
    //         sticker_addr_nxt = ((vga_in.vcount - STICKER_Y) * 18'd300) + (vga_in.hcount - STICKER_X);
    // end
end


// --- Rejestracja danych ---
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        logo_addr       <= '0;
        enter_addr      <= '0;
        font_addr       <= '0;
        brickwall_addr  <= '0;
        // sticker_addr     <= '0;

        enable_reg       <= 2'b0;

        vblnk_reg        <= 2'b0;
        hblnk_reg        <= 2'b0;
        in_logo_reg       <= 2'b0;
        in_button_reg     <= 2'b0;
        in_game_name_reg  <= 2'b0;
        in_authors_reg    <= 2'b0;
        // in_sticker_reg    <= 2'b0;

        px_h_in_char_reg <= 6'b0;
        enter_reg         <= 2'b0;
        
    end else begin
        logo_addr       <= logo_addr_nxt;
        enter_addr      <= enter_addr_nxt;
        font_addr       <= font_addr_nxt;
        brickwall_addr  <= brickwall_addr_nxt;
        // sticker_addr    <= sticker_addr_nxt;

        enable_reg       <= {enable_reg[0], enable_start_in};
        
        vblnk_reg        <= {vblnk_reg[0], vga_in.vblnk};
        hblnk_reg        <= {hblnk_reg[0], vga_in.hblnk};
        in_logo_reg       <= {in_logo_reg[0], in_logo};
        in_button_reg     <= {in_button_reg[0], in_button};
        in_game_name_reg  <= {in_game_name_reg[0], in_game_name};
        in_authors_reg    <= {in_authors_reg[0], in_authors};
        // in_sticker_reg    <= {in_sticker_reg[0], in_sticker};

        px_h_in_char_reg <= {px_h_in_char_reg[2:0], px_h_in_char};
        enter_reg         <= {enter_reg[0], enter};
    end
end

// --- Łączenie kolorów ---
always_comb begin
    if (hblnk_reg[1] || vblnk_reg[1] || !enable_reg[1]) begin 
        rgb_nxt = 12'h000;
    end else if (in_logo_reg[1]) begin 
        rgb_nxt = logo_rgb;
    end else if (in_button_reg[1]) begin 
        rgb_nxt = enter_px ? 12'hf_f_f : 12'h0_0_0;
        if (enter_reg[1])
            rgb_nxt = ~rgb_nxt;
    end else if (in_game_name_reg[1] && font_pixels[~px_h_in_char_reg[5:3]]) begin 
        rgb_nxt = GAME_NAME_COLOR;
    end else if (in_authors_reg[1] && font_pixels[~px_h_in_char_reg[5:3]]) begin 
        rgb_nxt = AUTHORS_COLOR;
    // end else if ((in_sticker_reg[1]) && (sticker_pixels != 12'h333) &&(sticker_pixels != 12'h233)) begin 
    //         rgb_nxt = sticker_pixels; // Kolor piksela naklejki
    end else begin  
        rgb_nxt = brickwall_pixels;
    end
end

// --- Wyjściowy rejestr ---
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rgb_out_start_bg <= '0;
                enable_start_out <= 1'b0;
    end else begin
        rgb_out_start_bg <= rgb_nxt;
        enable_start_out <= enable_reg[1];
    end
end

endmodule