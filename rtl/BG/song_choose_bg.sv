import vga_pkg::*;

module song_choose_bg (
    input logic clk,
    input logic rst_n,
    input logic enable_choose_in,
    input logic [7:0] button,

    input vga_if vga_in,
    
    output logic [11:0] rgb_out_choose_bg,
    output logic enable_choose_out,
    output logic [2:0] selected_song 
);

import game_pkg::*;

// --- PARAMETRY KOLORÓW --- 
localparam [11:0] BG_COLOR     = 12'h2_2_3;
localparam [11:0] TEXT_COLOR   = 12'hf_f_f;
localparam [11:0] CURSOR_COLOR = 12'hf_f_0; 

// --- PARAMETRY TEKSTU I SKALOWANIA ---
localparam TEXT_LEN = 16;   
localparam TEXT_SCALE = 2;  
localparam TEXT_ADDR_SHIFT = $clog2(TEXT_SCALE); 

// --- PARAMETRY POZYCJI ---
localparam START_X = 350; 
localparam START_Y = 100; 

localparam CURSOR_X = 250; 
localparam ROW_HEIGHT = 32; 
localparam ROW_STEP_SHIFT = 7; 

// --- LISTA PIOSENEK ---
localparam logic [0:TEXT_LEN-1] [7:0] SONG_0 = "1. Mi Bombo     ";
localparam logic [0:TEXT_LEN-1] [7:0] SONG_1 = "2. Never Gonna  ";
localparam logic [0:TEXT_LEN-1] [7:0] SONG_2 = "3. Give You Up  ";
localparam logic [0:TEXT_LEN-1] [7:0] SONG_3 = "4. Let It Down  ";
localparam logic [0:TEXT_LEN-1] [7:0] SONG_4 = "5. Desert You   ";

// --- SYGNAŁY WEWNĘTRZNE ---
logic [11:0] rgb_nxt;
logic [1:0] enable_reg;

logic [15:0] hoff_text, voff_text;
logic [7:0]  char_code;
logic [2:0]  px_h_in_char, d1_px_h_in_char;

logic in_text, d1_in_text;
logic in_cursor, d1_in_cursor;

logic [10:0] rel_y;
logic [2:0]  current_row;
logic [6:0]  y_in_row;

logic [10:0] font_addr;
logic [7:0]  font_pixels;

logic d1_vblnk, d1_hblnk;

// --- MODUŁ OPÓŹNIAJĄCY ---
delay  #(
        .WIDTH(2), 
        .CLK_DEL(1)
    )u_vga_in_del1(
        .clk(clk),
        .rst_n(rst_n),
        .din({vga_in.vblnk, vga_in.hblnk}),
        .dout({d1_vblnk, d1_hblnk})
    );

// --- INSTANCJA FONT ROM ---
font_rom u_font_rom (
    .clk(clk),
    .addr(font_addr),
    .char_line_pixels(font_pixels)
);

// --- LOGIKA STEROWANIA KURSOREM ---
always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        selected_song <= '0;
    end else begin
        if (button == ARR_LEFT) begin
            selected_song <= (selected_song + 3'd4) % 3'd5;
        end else if (button == ARR_RIGHT) begin
            selected_song <= (selected_song + 3'd1) % 3'd5;
        end
    end
end

// --- LOGIKA POZYCJI (Cykl 0) ---
always_comb begin
    in_text      = 1'b0;
    in_cursor    = 1'b0;
    font_addr    = '0;
    char_code    = '0;
    hoff_text    = '0;
    voff_text    = '0;
    px_h_in_char = '0;

    rel_y = vga_in.vcount - START_Y;
    current_row = rel_y >> ROW_STEP_SHIFT; 
    y_in_row    = rel_y[6:0];              

    if (vga_in.vcount >= START_Y && current_row < 5 && y_in_row < ROW_HEIGHT) begin
        
        if (vga_in.hcount >= CURSOR_X && vga_in.hcount < CURSOR_X + (8 << TEXT_ADDR_SHIFT)) begin
            if (current_row == selected_song) begin
                in_cursor = 1'b1;
                hoff_text = (vga_in.hcount - CURSOR_X) >> TEXT_ADDR_SHIFT;
                voff_text = y_in_row >> TEXT_ADDR_SHIFT;
                char_code = 8'h2D;
                font_addr = {char_code[6:0], 4'(voff_text[3:0])};
                px_h_in_char = hoff_text[2:0];
            end
        end
        
        else if (vga_in.hcount >= START_X && vga_in.hcount < START_X + (TEXT_LEN * 8 << TEXT_ADDR_SHIFT)) begin
            in_text = 1'b1;
            hoff_text = (vga_in.hcount - START_X) >> TEXT_ADDR_SHIFT;
            voff_text = y_in_row >> TEXT_ADDR_SHIFT;

            case (current_row)
                3'd0: char_code = SONG_0[hoff_text / 8];
                3'd1: char_code = SONG_1[hoff_text / 8];
                3'd2: char_code = SONG_2[hoff_text / 8];
                3'd3: char_code = SONG_3[hoff_text / 8];
                3'd4: char_code = SONG_4[hoff_text / 8];
                default: char_code = 8'h20; 
            endcase

            font_addr = {char_code[6:0], 4'(voff_text[3:0])};
            px_h_in_char = hoff_text[2:0];
        end
    end
end

// --- SYNCHRONIZACJA FLAG (Cykl 1) ---
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        d1_in_text      <= 1'b0;
        d1_in_cursor    <= 1'b0;
        d1_px_h_in_char <= '0;
    end else begin
        d1_in_text      <= in_text;
        d1_in_cursor    <= in_cursor;
        d1_px_h_in_char <= px_h_in_char;
    end
end

// --- ŁĄCZENIE KOLORÓW ---
always_comb begin
    if(d1_hblnk || d1_vblnk || !enable_reg[0]) begin
        rgb_nxt = 12'h0_0_0;
        
    end else if((d1_in_text || d1_in_cursor) && font_pixels[~d1_px_h_in_char]) begin 
        if (d1_in_cursor) begin
            rgb_nxt = CURSOR_COLOR;
        end else begin
            rgb_nxt = TEXT_COLOR;
        end
    end else begin 
        rgb_nxt = BG_COLOR;
    end
end

// --- WYJŚCIOWY REJESTR ---
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        rgb_out_choose_bg    <= '0;
        enable_reg      <= '0;
        enable_choose_out <= '0;
    end else begin
        enable_reg      <= {enable_reg[0], enable_choose_in}; 
        enable_choose_out <= enable_reg[1];
        rgb_out_choose_bg    <= rgb_nxt;
    end
end

endmodule