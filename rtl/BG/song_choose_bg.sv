import vga_pkg::*;

module song_choose_bg (
    input logic clk,
    input logic rst_n,               // Reset synchroniczny, aktywny stanem niskim
    input logic enable_choose_in,
    input [2:0] master_song,

    input vga_if vga_in,
    
    output logic [11:0] rgb_out_choose_bg,
    output logic enable_choose_out
);

import game_pkg::*;

// --- PARAMETRY KOLORÓW --- 
localparam [11:0] BG_COLOR     = 12'h2_2_3;
localparam [11:0] TEXT_COLOR   = 12'hf_f_f;
localparam [11:0] INSTR_TEXT_COLOR = 12'h0_f_f;
localparam [11:0] CURSOR_COLOR = 12'hf_f_0; 

// --- PARAMETRY TEKSTU I SKALOWANIA ---
localparam TEXT_SCALE = 2;
localparam BASE_CHAR_WIDTH = 8;
localparam BASE_CHAR_HEIGHT = 16;
localparam TEXT_ADDR_SHIFT = $clog2(TEXT_SCALE);
localparam CHAR_WIDTH = BASE_CHAR_WIDTH * TEXT_SCALE;
localparam CHAR_HEIGHT = BASE_CHAR_HEIGHT * TEXT_SCALE;

// --- INSTRUKCJA---
localparam INSTR_START_X = 64;
localparam INSTR_START_Y = 420; //;)
localparam INSTR_ROW_STEP_PIXELS = 48;
localparam INSTR_ROW_INDEX_WIDTH = $clog2(VER_PIXELS / INSTR_ROW_STEP_PIXELS + 1);
localparam logic [0:55] [7:0] INSTR_0 = "               HOW TO PLAY KEYBOARD HERO?               ";
localparam logic [0:55] [7:0] INSTR_1 = " To play, press STRUM < or > together with buttons 1-6. ";
localparam logic [0:55] [7:0] INSTR_2 = "       Buttons 1-6 match the colors of the notes.       ";
localparam logic [0:55] [7:0] INSTR_3 = " Hold the matching button for long notes until they end.";
localparam logic [0:55] [7:0] INSTR_4 = "  Use STRUM < or > at the same time as the note button. ";
localparam logic [0:55] [7:0] INSTR_5 = "TO NAVIGATE THRU GAME STAGES USE ENTER BUTTON ESC BUTTON";

// --- PIOSENKI---
localparam SONG_LEN = 24;
localparam SONG_NAME_START_X = 275; 
localparam SONG_NAME_START_Y = 100; 
localparam CURSOR_X = 250; 
localparam BASE_ROW_STEP_PIXELS = 32;
localparam ROW_HEIGHT = CHAR_HEIGHT;
localparam ROW_STEP_PIXELS = BASE_ROW_STEP_PIXELS * TEXT_SCALE;
localparam ROW_STEP_SHIFT = $clog2(ROW_STEP_PIXELS);
localparam ROW_INDEX_WIDTH = $clog2(VER_PIXELS / ROW_STEP_PIXELS + 1);
localparam logic [0:SONG_LEN-1] [7:0] SONG_0 = "1. Wlazl kotek na plotek";
localparam logic [0:SONG_LEN-1] [7:0] SONG_1 = "2. Hejnal mariacki      ";
localparam logic [0:SONG_LEN-1] [7:0] SONG_2 = "3. Stairway to Heaven   ";
localparam logic [0:SONG_LEN-1] [7:0] SONG_3 = "4. Literka A, literka B ";

localparam HEADING_NAME_START_X = 223; 
localparam HEADING_NAME_START_Y = 33; 
localparam logic [0:45] [7:0] Heading = "CHOOSE YOUR SONG FROM THE LIST BELOW USING < >";


// --- SYGNAŁY WEWNĘTRZNE ---
logic [11:0] rgb_nxt;
logic [1:0] enable_reg;
logic [2:0] selected_song;

logic [15:0] hoff_text, voff_text;
logic [7:0]  char_code;
logic [2:0]  px_h_in_char;

// Rejestry pipeline do synchronizacji z opóźnieniem pamięci ROM 
logic d1_vblnk, d2_vblnk;
logic d1_hblnk, d2_hblnk;
logic in_text, d1_in_text, d2_in_text;
logic in_instruction, d1_in_instruction, d2_in_instruction;
logic in_cursor, d1_in_cursor, d2_in_cursor;
logic [2:0] d1_px_h_in_char, d2_px_h_in_char;

logic [10:0] rel_y;
logic [ROW_INDEX_WIDTH-1:0] current_row;
logic [7:0]  y_in_row;
logic [INSTR_ROW_INDEX_WIDTH-1:0] instruction_row;
logic [6:0]  y_in_instruction;

logic [10:0] font_addr, font_addr_nxt;
logic [7:0]  font_pixels;

// --- INSTANCJA FONT ROM ---
font_rom u_font_rom (
    .clk(clk),
    // .rst_n(rst_n),
    .addr(font_addr),
    .char_line_pixels(font_pixels)
);

// --- CYKL 0: Logika kombinacyjna wyliczania adresów i flag ---
always_comb begin
    in_text       = 1'b0;
    in_instruction = 1'b0;
    in_cursor     = 1'b0;
    font_addr_nxt = '0;
    char_code     = '0;
    hoff_text     = '0;
    voff_text     = '0;
    px_h_in_char  = '0;

    rel_y       = vga_in.vcount - SONG_NAME_START_Y;
    current_row = rel_y >> ROW_STEP_SHIFT;
    y_in_row    = rel_y & (ROW_STEP_PIXELS - 1);
    instruction_row = '0;
    y_in_instruction = '0;

    if (vga_in.vcount >= HEADING_NAME_START_Y  && vga_in.vcount < HEADING_NAME_START_Y + CHAR_HEIGHT &&
        vga_in.hcount >= HEADING_NAME_START_X && vga_in.hcount < HEADING_NAME_START_X + 36 * CHAR_WIDTH) begin
            in_text   = 1'b1;
            hoff_text = (vga_in.hcount - HEADING_NAME_START_X) >> TEXT_ADDR_SHIFT;
            voff_text = (vga_in.vcount - HEADING_NAME_START_Y) >> TEXT_ADDR_SHIFT;

            char_code = Heading[hoff_text >> 3];
            font_addr_nxt = {char_code[6:0], 4'(voff_text[3:0])};
            px_h_in_char  = hoff_text[2:0];
    end
    

    if (vga_in.vcount >= SONG_NAME_START_Y && current_row < 4 && y_in_row < ROW_HEIGHT) begin
        
        // Logika kursora
        if (vga_in.hcount >= CURSOR_X && vga_in.hcount < CURSOR_X + CHAR_WIDTH) begin
            if (current_row == selected_song) begin
                in_cursor     = 1'b1;
                hoff_text     = (vga_in.hcount - CURSOR_X) >> TEXT_ADDR_SHIFT;
                voff_text     = y_in_row >> TEXT_ADDR_SHIFT;
                char_code     = 8'h2D;
                font_addr_nxt = {char_code[6:0], 4'(voff_text[3:0])};
                px_h_in_char  = hoff_text[2:0];
            end
        end
        
        // Logika TEKSTU PIOSENEK
        else if (vga_in.hcount >= SONG_NAME_START_X && vga_in.hcount < SONG_NAME_START_X + SONG_LEN * CHAR_WIDTH) begin
            in_text   = 1'b1;
            hoff_text = (vga_in.hcount - SONG_NAME_START_X) >> TEXT_ADDR_SHIFT;
            voff_text = y_in_row >> TEXT_ADDR_SHIFT;

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
    end //Logika tekstu instrukcji 
    else if (vga_in.vcount >= INSTR_START_Y && vga_in.vcount < INSTR_START_Y + 5 * INSTR_ROW_STEP_PIXELS &&
                 vga_in.hcount >= INSTR_START_X && vga_in.hcount < INSTR_START_X + 56 * CHAR_WIDTH) begin
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
        end else begin
            instruction_row = 5;
            y_in_instruction = vga_in.vcount - (INSTR_START_Y + 5 * INSTR_ROW_STEP_PIXELS);
        end

        if (y_in_instruction < ROW_HEIGHT) begin
        in_instruction = 1'b1;
        in_text   = 1'b1;
        hoff_text = (vga_in.hcount - INSTR_START_X) >> TEXT_ADDR_SHIFT;
        voff_text = y_in_instruction >> TEXT_ADDR_SHIFT;

        case (instruction_row)
            0: char_code = INSTR_0[hoff_text >> 3];
            1: char_code = INSTR_1[hoff_text >> 3];
            2: char_code = INSTR_2[hoff_text >> 3];
            3: char_code = INSTR_3[hoff_text >> 3];
            4: char_code = INSTR_4[hoff_text >> 3];
            5: char_code = INSTR_5[hoff_text >> 3];
            default: char_code = 8'h20;
        endcase

        font_addr_nxt = {char_code[6:0], 4'(voff_text[3:0])};
        px_h_in_char  = hoff_text[2:0];
        end
    end
end

// --- CYKL 1: Rejestracja adresu ROM oraz pierwszy stopień opóźnień ---
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        selected_song   <= '0;
        font_addr       <= '0;
        
        d1_vblnk        <= 1'b0;
        d1_hblnk        <= 1'b0;
        d1_in_text      <= 1'b0;
        d1_in_instruction <= 1'b0;
        d1_in_cursor    <= 1'b0;
        d1_px_h_in_char <= '0;
    end else begin
        selected_song   <= master_song; // Zatrzaskiwanie wejścia wyboru piosenki
        font_addr       <= font_addr_nxt;
        
        d1_vblnk        <= vga_in.vblnk;
        d1_hblnk        <= vga_in.hblnk;
        d1_in_text      <= in_text;
        d1_in_instruction <= in_instruction;
        d1_in_cursor    <= in_cursor;
        d1_px_h_in_char <= px_h_in_char;
    end
end

// --- CYKL 2: Drugi stopień opóźnień (Wyrównanie z wyjściem danych z FONT ROM) ---
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d2_vblnk        <= 1'b0;
        d2_hblnk        <= 1'b0;
        d2_in_text      <= 1'b0;
        d2_in_instruction <= 1'b0;
        d2_in_cursor    <= 1'b0;
        d2_px_h_in_char <= '0;
    end else begin
        d2_vblnk        <= d1_vblnk;
        d2_hblnk        <= d1_hblnk;
        d2_in_text      <= d1_in_text;
        d2_in_instruction <= d1_in_instruction;
        d2_in_cursor    <= d1_in_cursor;
        d2_px_h_in_char <= d1_px_h_in_char;
    end
end

// --- ŁĄCZENIE KOLORÓW (Logika kombinacyjna w Cyklu 2) ---
always_comb begin
    if (d2_hblnk || d2_vblnk || !enable_reg[1]) begin
        rgb_nxt = 12'h0_0_0;
    end else if ((d2_in_text || d2_in_cursor) && font_pixels[~d2_px_h_in_char]) begin 
        if (d2_in_cursor) begin
            rgb_nxt = CURSOR_COLOR;
        end else if (d2_in_instruction) begin
            rgb_nxt = INSTR_TEXT_COLOR;
        end else begin
            rgb_nxt = TEXT_COLOR;
        end
    end else begin 
        rgb_nxt = BG_COLOR;
    end
end

// --- CYKL 3: Wyściowy rejestr (Ostateczne wystawienie stabilnego RGB) ---
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rgb_out_choose_bg  <= '0;
        enable_reg         <= '0;
        enable_choose_out  <= '0;
    end else begin
        enable_reg         <= {enable_reg[0], enable_choose_in}; 
        enable_choose_out  <= enable_reg[1];
        rgb_out_choose_bg  <= rgb_nxt;
    end
end

endmodule