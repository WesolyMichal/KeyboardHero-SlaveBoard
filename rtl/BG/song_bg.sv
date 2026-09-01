/*
 * Copyright (C) 2026  AGH University of Science and Technology
 * MTM UEC2
 * Author: Jakub Suder
 *
 * Description:
 * This is module responsible for creating backgroud for PLAY_SONG state of slave_FSM.
 */

import vga_pkg::*;
import bg_pkg::*;

module song_bg (
    input logic clk,
    input logic rst_n,               
    input logic enable_song_in,

    input vga_if vga_in,

    output logic [11:0] rgb_out_song_bg,
    output logic enable_song_out
);

// --- SYGNAŁY WEWNĘTRZNE ---
logic [11:0] rgb_nxt;
logic [1:0]  enable_reg;

logic [16:0] hoff_crowd1, voff_crowd1;
logic [16:0] hoff_crowd2, voff_crowd2;

// Flagi kombinacyjne
logic in_neck, in_line, in_crowd1, in_crowd2;
logic in_crowd1_extension, in_crowd2_extension;

// Rejestry opóźniające 
logic [1:0] vblnk_reg, hblnk_reg;
logic [1:0] in_neck_reg, in_line_reg, in_crowd1_reg, in_crowd2_reg;
logic [1:0] in_crowd1_extension_reg, in_crowd2_extension_reg;

//Sygnały dla pamięci ROM
logic [16:0] crowd1_addr, crowd1_addr_nxt, crowd2_addr, crowd2_addr_nxt;
logic [11:0] crowd1_px, crowd2_px;

// --- INSTANCJE ROM ---

crowd1_rom u_crowd1_rom (
    .clk,
    .addr(crowd1_addr),
    .crowd1_px
);

crowd2_rom u_crowd2_rom (
    .clk,
    .addr(crowd2_addr),
    .crowd2_px
);

// --- Logika kombinacyjna wyliczania adresów i flag ---
always_comb begin
    in_neck        = 1'b0;
    in_line        = 1'b0;
    in_crowd1      = 1'b0;
    in_crowd2      = 1'b0;
    in_crowd1_extension = 1'b0;
    in_crowd2_extension = 1'b0;
    crowd1_addr_nxt = '0;
    crowd2_addr_nxt = '0;

    // Logika GRYFU i Linii
    if ((vga_in.hcount >= NECK_X && vga_in.hcount <= NECK_X + NECK_WIDTH) && 
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

    // Logika CROWD1
    if ((vga_in.hcount >= CROWD1_X && vga_in.hcount < CROWD1_X + CROWD1_WIDTH * CROWD1_SCALE) &&
        (vga_in.vcount >= CROWD1_Y && vga_in.vcount < CROWD1_Y + CROWD1_HEIGHT * CROWD1_SCALE)) begin
            in_crowd1 = 1'b1;
            hoff_crowd1 = (vga_in.hcount - CROWD1_X) >> CROWD1_ADDR_SHIFT;
            voff_crowd1 = (vga_in.vcount - CROWD1_Y) >> CROWD1_ADDR_SHIFT;
            crowd1_addr_nxt = (voff_crowd1 << 8) + (voff_crowd1 << 6) + hoff_crowd1;
        end
    // Logika CROWD2
    if((vga_in.hcount >= CROWD2_X && vga_in.hcount < CROWD2_X + CROWD2_WIDTH * CROWD2_SCALE) &&
        (vga_in.vcount >= CROWD2_Y && vga_in.vcount < CROWD2_Y + CROWD2_HEIGHT * CROWD2_SCALE)) begin
            in_crowd2 = 1'b1;
            hoff_crowd2 = (vga_in.hcount - CROWD2_X) >> CROWD2_ADDR_SHIFT;
            voff_crowd2 = (vga_in.vcount - CROWD2_Y) >> CROWD2_ADDR_SHIFT;
            crowd2_addr_nxt = (voff_crowd2 << 8) + (voff_crowd2 << 6) + hoff_crowd2;
    end
    if((vga_in.hcount >= CROWD1_X && vga_in.hcount < CROWD1_X + CROWD1_WIDTH * CROWD1_SCALE) &&
        (vga_in.vcount >= CROWD1_Y + CROWD1_HEIGHT && vga_in.vcount < 768) && (!in_neck)) begin
            in_crowd1_extension = 1'b1;
    end 
    if((vga_in.hcount >= CROWD2_X && vga_in.hcount < CROWD2_X + CROWD2_WIDTH * CROWD2_SCALE) &&
        (vga_in.vcount >= CROWD2_Y + CROWD2_HEIGHT && vga_in.vcount < 768) && (!in_neck)) begin
            in_crowd2_extension = 1'b1;
    end 
end

// --- Rejestracja danych ---
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crowd1_addr     <= '0;
        crowd2_addr     <= '0;

        enable_reg          <= '0;

        vblnk_reg        <= '0;
        hblnk_reg        <= '0;
        in_neck_reg      <= '0;
        in_line_reg      <= '0;
        in_crowd1_reg     <= '0;
        in_crowd2_reg     <= '0;
        in_crowd1_extension_reg     <= '0;
        in_crowd2_extension_reg     <= '0;
    end else begin
        crowd1_addr     <= crowd1_addr_nxt;
        crowd2_addr     <= crowd2_addr_nxt;

        enable_reg      <= {enable_reg[0], enable_song_in};
        
        vblnk_reg        <= {vblnk_reg[0], vga_in.vblnk};
        hblnk_reg        <= {hblnk_reg[0], vga_in.hblnk};
        in_neck_reg      <= {in_neck_reg[0], in_neck};
        in_line_reg      <= {in_line_reg[0], in_line};
        in_crowd1_reg     <= {in_crowd1_reg[0], in_crowd1};
        in_crowd2_reg     <= {in_crowd2_reg[0], in_crowd2};
        in_crowd1_extension_reg     <= {in_crowd1_extension_reg[0], in_crowd1_extension};
        in_crowd2_extension_reg     <= {in_crowd2_extension_reg[0], in_crowd2_extension};
    end
end

// --- Łączenie kolorów ---
always_comb begin
    if (hblnk_reg[1] || vblnk_reg[1] || !enable_reg[1]) begin
        rgb_nxt = 12'h000;
          
    end else if (in_line_reg[1]) begin
        rgb_nxt = LINE_COLOR;
        
    end else if (in_neck_reg[1]) begin
        rgb_nxt = NECK_COLOR;
        
    end else if (in_crowd1_reg[1]) begin
        rgb_nxt = crowd1_px;
    end else if (in_crowd2_reg[1]) begin
        rgb_nxt = crowd2_px;

    end else if (in_crowd1_extension_reg[1]) begin
        rgb_nxt = 12'h522;
    end else if (in_crowd2_extension_reg[1]) begin
        rgb_nxt = 12'h322;
    end else begin
        rgb_nxt = BG_COLOR;
    end
end

// --- Wyjściowy rejestr ---
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rgb_out_song_bg <= '0;
        enable_song_out <= '0;
    end else begin
        enable_song_out <= enable_reg[1];
        rgb_out_song_bg <= rgb_nxt;
    end
end

endmodule