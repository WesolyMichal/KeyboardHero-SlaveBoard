/*
 * Copyright (C) 2026  AGH University of Science and Technology
 * MTM UEC2
 * Author: Jakub Suder
 *
 * Description:
 * This is module responsible for creating backgroud for SONG_CHOOSE state of slave_FSM.
 */

import vga_pkg::*;
import bg_pkg::*;

module song_choose_bg (
    input logic clk,
    input logic rst_n,
    input logic enable_choose_in,
    input [1:0] master_song,

    input vga_if vga_in,
    
    output logic [11:0] rgb_out_choose_bg,
    output logic enable_choose_out
);

// --- SYGNAŁY WEWNĘTRZNE ---
logic [11:0] rgb_nxt;

logic [1:0] selected_song;

logic [15:0] hoff_text, voff_text;
logic [7:0]  char_code;
logic [2:0]  px_h_in_char;

logic [10:0] rel_y;
logic [ROW_INDEX_WIDTH-1:0] current_row;
logic [7:0]  y_in_row;
logic [INSTR_ROW_INDEX_WIDTH-1:0] instruction_row;
logic [6:0]  y_in_instruction;

//Flagi kombinacyjne
logic in_text, in_instruction, in_cursor;

// Rejestry opóźniające
logic [1:0] vblnk_reg, hblnk_reg;
logic [1:0] in_text_reg, in_instruction_reg, in_cursor_reg;
logic [5:0] px_h_in_char_reg;
logic [1:0] enable_reg;

// Sygnały dla pamięci ROM
logic [10:0] font_addr, font_addr_nxt;
logic [7:0]  font_pixels;
logic [10:0] brickwall_x, brickwall_y;
logic [17:0] brickwall_addr_nxt, brickwall_addr;
logic [11:0] brickwall_pixels;

// --- INSTANCJE ROM ---
font_rom u_font_rom (
    .clk(clk),
    .addr(font_addr),
    .char_line_pixels(font_pixels)
);

brickwall_rom u_brickwall_rom (
    .clk,
    .addr(brickwall_addr),
    .brickwall_px(brickwall_pixels)
 );

// --- Logika kombinacyjna wyliczania adresów i flag ---
always_comb begin
    in_text       = '0;
    in_instruction = '0;
    in_cursor     = '0;

    font_addr_nxt = '0;
    char_code     = '0;
    hoff_text     = '0;
    voff_text     = '0;
    px_h_in_char  = '0;

    brickwall_addr_nxt = '0;

    brickwall_x = wrap_coordinate(vga_in.hcount, 11'd600);
    brickwall_y = wrap_coordinate(vga_in.vcount, 11'd274);
    brickwall_y = wrap_coordinate(brickwall_y, 11'd274);
    brickwall_addr_nxt = (brickwall_y * 17'd600) + brickwall_x;
    
    rel_y       = vga_in.vcount - SONG_NAME_START_Y;
    current_row = rel_y >> ROW_STEP_SHIFT;
    y_in_row    = rel_y & (ROW_STEP_PIXELS - 1);
    instruction_row = '0;
    y_in_instruction = '0;
    // Logika NAGŁÓWKA
    if (vga_in.vcount >= HEADING_NAME_START_Y  && vga_in.vcount < HEADING_NAME_START_Y + CHAR_HEIGHT &&
        vga_in.hcount >= HEADING_NAME_START_X && vga_in.hcount < HEADING_NAME_START_X + 46 * CHAR_WIDTH) begin
            in_text   = 1'b1;
            hoff_text = (vga_in.hcount - HEADING_NAME_START_X) >> SCHOOSE_TEXT_ADDR_SHIFT;
            voff_text = (vga_in.vcount - HEADING_NAME_START_Y) >> SCHOOSE_TEXT_ADDR_SHIFT;

            char_code = Heading[hoff_text >> 3];
            font_addr_nxt = {char_code[6:0], 4'(voff_text[3:0])};
            px_h_in_char  = hoff_text[2:0];
    end
    

    if (vga_in.vcount >= SONG_NAME_START_Y && current_row < 4 && y_in_row < ROW_HEIGHT) begin
        
        // Logika kursora
        if (vga_in.hcount >= CURSOR_X && vga_in.hcount < CURSOR_X + CHAR_WIDTH) begin
            if (current_row == selected_song) begin
                in_cursor     = 1'b1;
                hoff_text     = (vga_in.hcount - CURSOR_X) >> SCHOOSE_TEXT_ADDR_SHIFT;
                voff_text     = y_in_row >> SCHOOSE_TEXT_ADDR_SHIFT;
                char_code     = 8'h2D;
                font_addr_nxt = {char_code[6:0], 4'(voff_text[3:0])};
                px_h_in_char  = hoff_text[2:0];
            end
        end
        
        // Logika nazw piosenek
        else if (vga_in.hcount >= SONG_NAME_START_X && vga_in.hcount < SONG_NAME_START_X + SONG_LEN * CHAR_WIDTH) begin
            in_text   = 1'b1;
            hoff_text = (vga_in.hcount - SONG_NAME_START_X) >> SCHOOSE_TEXT_ADDR_SHIFT;
            voff_text = y_in_row >> SCHOOSE_TEXT_ADDR_SHIFT;

            case (current_row)
                3'd0: char_code = SONG_0[hoff_text >> 3];
                3'd1: char_code = SONG_1[hoff_text >> 3];
                3'd2: char_code = SONG_2[hoff_text >> 3];
                3'd3: char_code = SONG_3[hoff_text >> 3];
                default: char_code = 8'h20; 
            endcase

            font_addr_nxt = {char_code[6:0], 4'(voff_text[3:0])};
            px_h_in_char  = hoff_text[2:0];
        end
    end 
    //Logika tekstu instrukcji 
    else if (vga_in.vcount >= INSTR_START_Y && vga_in.vcount < INSTR_START_Y + 7 * INSTR_ROW_STEP_PIXELS &&
                 vga_in.hcount >= INSTR_START_X && vga_in.hcount < INSTR_START_X + CHAR_IN_LINE * CHAR_WIDTH) begin
        if (vga_in.vcount < INSTR_START_Y + INSTR_ROW_STEP_PIXELS) begin
            instruction_row = 0;
            y_in_instruction = vga_in.vcount - INSTR_START_Y;
        end else if (vga_in.vcount < INSTR_START_Y + 2 * INSTR_ROW_STEP_PIXELS) begin
            instruction_row = 1;
            y_in_instruction = vga_in.vcount - (INSTR_START_Y + INSTR_ROW_STEP_PIXELS);
        end else if (vga_in.vcount < INSTR_START_Y + 3 * INSTR_ROW_STEP_PIXELS) begin
            instruction_row = 2;
            y_in_instruction = vga_in.vcount - (INSTR_START_Y + 2 * INSTR_ROW_STEP_PIXELS);
        end else if (vga_in.vcount < INSTR_START_Y + 4 * INSTR_ROW_STEP_PIXELS) begin
            instruction_row = 3;
            y_in_instruction = vga_in.vcount - (INSTR_START_Y + 3 * INSTR_ROW_STEP_PIXELS);
        end else if (vga_in.vcount < INSTR_START_Y + 5 * INSTR_ROW_STEP_PIXELS) begin
            instruction_row = 4;
            y_in_instruction = vga_in.vcount - (INSTR_START_Y + 4 * INSTR_ROW_STEP_PIXELS);
        end else if (vga_in.vcount < INSTR_START_Y + 6 * INSTR_ROW_STEP_PIXELS) begin
            instruction_row = 5;
            y_in_instruction = vga_in.vcount - (INSTR_START_Y + 5 * INSTR_ROW_STEP_PIXELS);
        end else begin
            instruction_row = 6;
            y_in_instruction = vga_in.vcount - (INSTR_START_Y + 6 * INSTR_ROW_STEP_PIXELS);
        end

        if (y_in_instruction < ROW_HEIGHT) begin
        in_instruction = 1'b1;
        in_text   = 1'b1;
        hoff_text = (vga_in.hcount - INSTR_START_X) >> SCHOOSE_TEXT_ADDR_SHIFT;
        voff_text = y_in_instruction >> SCHOOSE_TEXT_ADDR_SHIFT;

        case (instruction_row)
            5'd0: char_code = INSTR_0[hoff_text >> 3];
            5'd1: char_code = INSTR_1[hoff_text >> 3];
            5'd2: char_code = INSTR_2[hoff_text >> 3];
            5'd3: char_code = INSTR_3[hoff_text >> 3];
            5'd4: char_code = INSTR_4[hoff_text >> 3];
            5'd5: char_code = INSTR_5[hoff_text >> 3];
            5'd6: char_code = INSTR_6[hoff_text >> 3];
            default: char_code = 8'h20;
        endcase

        font_addr_nxt = {char_code[6:0], 4'(voff_text[3:0])};
        px_h_in_char  = hoff_text[2:0];
        end
    end
end

// --- Rejestracja danych ---
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        font_addr       <= '0;
        brickwall_addr  <= '0;
        
        selected_song   <= '0;
        
        enable_reg          <= '0;

        vblnk_reg           <= '0;
        hblnk_reg           <= '0;
        in_text_reg         <= '0;
        in_instruction_reg  <= '0;
        in_cursor_reg       <= '0;
        px_h_in_char_reg    <= '0;
    end else begin
        font_addr       <= font_addr_nxt;
        brickwall_addr  <= brickwall_addr_nxt;

        selected_song   <= master_song;
        
        enable_reg          <= {enable_reg[0], enable_choose_in}; 
        
        vblnk_reg           <= {vblnk_reg[0], vga_in.vblnk};
        hblnk_reg           <= {hblnk_reg[0], vga_in.hblnk};
        in_text_reg         <= {in_text_reg[0], in_text};
        in_instruction_reg  <= {in_instruction_reg[0], in_instruction};
        in_cursor_reg       <= {in_cursor_reg[0], in_cursor};
        px_h_in_char_reg    <= {px_h_in_char_reg[2:0], px_h_in_char};
    end
end

// --- łączenie kolorów ---
always_comb begin
    if (hblnk_reg[1] || vblnk_reg[1] || !enable_reg[1]) begin
        rgb_nxt = 12'h0_0_0;
    end else if ((in_text_reg[1] || in_cursor_reg[1]) && font_pixels[~px_h_in_char_reg[5:3]]) begin 
        if (in_cursor_reg[1]) begin
            rgb_nxt = CURSOR_COLOR;
        end else if (in_instruction_reg[1]) begin
            rgb_nxt = INSTR_TEXT_COLOR;
        end else begin
            rgb_nxt = TEXT_COLOR;
        end
    end else begin 
        rgb_nxt = brickwall_pixels;
    end
end

// --- Wyściowy rejestr ---
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rgb_out_choose_bg  <= '0;
        enable_choose_out  <= '0;
    end else begin
        enable_choose_out  <= enable_reg[1];
        rgb_out_choose_bg  <= rgb_nxt;
    end
end

endmodule