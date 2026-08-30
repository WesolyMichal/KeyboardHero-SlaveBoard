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

localparam CROWD1_X = 64;
localparam CROWD1_Y = 612;
localparam CROWD1_WIDTH = 256;
localparam CROWD1_HEIGHT = 212;

localparam CROWD2_X = 704;
localparam CROWD2_Y = 635;
localparam CROWD2_WIDTH = 256;
localparam CROWD2_HEIGHT = 235;

// --- SYGNAŁY WEWNĘTRZNE ---
logic [11:0] rgb_nxt;
logic [1:0]  enable_reg;

logic [15:0] hoff_mibombo_l, voff_mibombo_l;
logic [15:0] hoff_mibombo_r, voff_mibombo_r;
logic [15:0] hoff_crowd1, voff_crowd1;
logic [15:0] hoff_crowd2, voff_crowd2;

// Flagi kombinacyjne
logic in_neck, in_line, in_mibombo_l, in_mibombo_r, in_crowd1, in_crowd2;

// Rejestry opóźniające 
logic [1:0] vblnk_reg, hblnk_reg;
logic [1:0] in_neck_reg, in_line_reg, in_mibombo_l_reg, in_mibombo_r_reg, in_crowd1_reg, in_crowd2_reg;

//Sygnały dla pamięci ROM
logic [15:0] mibombo_addr, mibombo_addr_nxt;
logic [11:0] mibombo_pixel; 

logic [15:0] crowd1_addr, crowd1_addr_nxt, crowd2_addr, crowd2_addr_nxt;
logic [11:0] crowd1_px, crowd2_px;

// --- ROM DLA GŁOŚNIKA ---
mibombo_rom u_mibombo_rom (
    .clk(clk),
    .addr(mibombo_addr),
    .mibombo_out(mibombo_pixel)
);

// --- Logika kombinacyjna wyliczania adresów i flag ---
always_comb begin
    in_neck        = 1'b0;
    in_line        = 1'b0;
    in_mibombo_l   = 1'b0;
    in_mibombo_r   = 1'b0;
    in_crowd1      = 1'b0;
    in_crowd2      = 1'b0;
    hoff_mibombo_l = '0;
    voff_mibombo_l = '0;
    hoff_mibombo_r = '0;
    voff_mibombo_r = '0;
    hoff_crowd1 = '0;
    voff_crowd1 = '0;
    hoff_crowd2 = '0;
    voff_crowd2 = '0;

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

    // Logika MIBOMBO PRAWEGO
    if ((vga_in.hcount >= MIBOMBO_R_X && vga_in.hcount < MIBOMBO_R_X + MIBOMBO_WIDTH) &&
        (vga_in.vcount >= MIBOMBO_Y && vga_in.vcount < MIBOMBO_Y + MIBOMBO_HEIGHT)) begin
        in_mibombo_r   = 1'b1;
        hoff_mibombo_r = 16'(vga_in.hcount - MIBOMBO_R_X);
        voff_mibombo_r = 16'(vga_in.vcount - MIBOMBO_Y);
    end

    // Logika MIBOMBO LEWEGO 
    if ((vga_in.hcount >= MIBOMBO_L_X && vga_in.hcount < MIBOMBO_L_X + MIBOMBO_WIDTH) &&
        (vga_in.vcount >= MIBOMBO_Y && vga_in.vcount < MIBOMBO_Y + MIBOMBO_HEIGHT)) begin
        in_mibombo_l   = 1'b1;
        hoff_mibombo_l = 16'(MIBOMBO_WIDTH - 1 - (vga_in.hcount - MIBOMBO_L_X));
        voff_mibombo_l = 16'(vga_in.vcount - MIBOMBO_Y);
    end

    // Multipleksowanie adresu dla ROMu, aby lewy głośnik nie nadpisywał prawego
    if (in_mibombo_l) begin
        mibombo_addr_nxt = (voff_mibombo_l * MIBOMBO_WIDTH) + hoff_mibombo_l;
    end else if (in_mibombo_r) begin
        mibombo_addr_nxt = (voff_mibombo_r * MIBOMBO_WIDTH) + hoff_mibombo_r;
    end else begin
        mibombo_addr_nxt = '0;
    end

    if((vga_in.hcount >= CROWD1_X && vga_in.hcount < CROWD1_X + CROWD1_WIDTH) &&
        (vga_in.vcount >= CROWD1_Y && vga_in.vcount < CROWD1_Y + CROWD1_HEIGHT)) begin
            in_crowd1 = 1'b1;
            hoff_crowd1 = vga_in.hcount - CROWD1_WIDTH;
            voff_crowd1 = vga_in.vcount - CROWD1_HEIGHT;
            crowd1_addr = {voff_crowd1[7:0], voff_crowd1[7:0]};
        end

    if((vga_in.hcount >= CROWD2_X && vga_in.hcount < CROWD2_X + CROWD2_WIDTH) &&
        (vga_in.vcount >= CROWD2_Y && vga_in.vcount < CROWD2_Y + CROWD2_HEIGHT)) begin
            in_crowd2 = 1'b1;
            hoff_crowd2 = vga_in.hcount - CROWD2_WIDTH;
            voff_crowd2 = vga_in.vcount - CROWD2_HEIGHT;
            crowd2_addr = {voff_crowd2[7:0], voff_crowd2[7:0]};
        end
end

// --- Rejestracja danych ---
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mibombo_addr    <= '0;
        crowd1_addr     <= '0;
        crowd2_addr     <= '0;

        enable_reg          <= '0;

        vblnk_reg        <= '0;
        hblnk_reg        <= '0;
        in_neck_reg      <= '0;
        in_line_reg      <= '0;
        in_mibombo_l_reg <= '0;
        in_mibombo_r_reg <= '0;
        in_crowd1_reg     <= '0;
        in_crowd2_reg     <= '0;
    end else begin
        mibombo_addr    <= mibombo_addr_nxt;
        crowd1_addr     <= crowd1_addr_nxt;
        crowd2_addr     <= crowd2_addr_nxt;

        enable_reg      <= {enable_reg[0], enable_song_in};
        
        vblnk_reg        <= {vblnk_reg[0], vga_in.vblnk};
        hblnk_reg        <= {hblnk_reg[0], vga_in.hblnk};
        in_neck_reg      <= {in_neck_reg[0], in_neck};
        in_line_reg      <= {in_line_reg[0], in_line};
        in_mibombo_l_reg <= {in_mibombo_l_reg[0], in_mibombo_l};
        in_mibombo_r_reg <= {in_mibombo_r_reg[0], in_mibombo_r};
        in_crowd1_reg     <= {in_crowd1_reg[0], in_crowd1};
        in_crowd2_reg     <= {in_crowd2_reg[0], in_crowd2};
    end
end

// --- Łączenie kolorów ---
always_comb begin
    if (hblnk_reg[1] || vblnk_reg[1] || !enable_reg[1]) begin
        rgb_nxt = 12'h000;
        
    end else if ((in_mibombo_l_reg[1] || in_mibombo_r_reg[1]) && mibombo_pixel) begin 
        
        rgb_nxt = MIBOMBO_OUTLINE; 
        
    end else if (in_line_reg[1]) begin
        rgb_nxt = LINE_COLOR;
        
    end else if (in_neck_reg[1]) begin
        rgb_nxt = NECK_COLOR;
        
    end else if (in_crowd1_reg[1]) begin
        rgb_nxt = crowd1_px;
    end else if (in_crowd2_reg[1]) begin
        rgb_nxt = crowd2_px;
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