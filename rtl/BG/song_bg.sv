import vga_pkg::*;

module song_bg (
    input logic clk,
    input logic rst_n,
    input logic enable_song_in,

    input vga_if vga_in,

    output logic [11:0] rgb_out_song_bg,
    output logic enable_song_out
);

// --- PARAMETRY KOLORÓW --- 
localparam [11:0] BG_COLOR   = 12'h3_3_5;
localparam [11:0] NECK_COLOR = 12'h1_1_2; 
localparam [11:0] LINE_COLOR = 12'h8_8_9; 

// Kolory Mibombo
localparam [11:0] MIBOMBO_OUTLINE = 12'hf_f_f;
localparam [11:0] MIBOMBO_INNER   = 12'h7_7_7; 

// --- PARAMETRY GRYFU  ---
localparam NECK_X      = 320; 
localparam NECK_Y      = 0;
localparam NECK_WIDTH  = 384; 
localparam NECK_HEIGHT = 768;

// --- PARAMETRY GŁOŚNIKÓW ---
localparam MIBOMBO_WIDTH  = 218;
localparam MIBOMBO_HEIGHT = 292;
localparam MIBOMBO_Y      = 400; 

localparam MIBOMBO_L_X    = 80;  
localparam MIBOMBO_R_X    = 690; 


// --- SYGNAŁY WEWNĘTRZNE ---
logic [11:0] rgb_nxt;

logic [15:0] hoff_mibombo, voff_mibombo;
logic [15:0] mibombo_addr;
logic mibombo_pixel; 

logic [1:0] enable_reg;

// Flagi kombinacyjne
logic in_neck, in_line;
logic in_mibombo_l, in_mibombo_r;

logic d1_in_neck, d1_in_line;
logic d1_in_mibombo_l, d1_in_mibombo_r;

logic d1_vblnk, d1_hblnk;

// --- MODUŁ OPÓŹNIAJĄCY ---
delay  #(
        .WIDTH(2), 
        .CLK_DEL(1)
    )u_vga_in_del1(
        .clk,
        .rst_n,
        .din({vga_in.vblnk, vga_in.hblnk}),
        .dout({d1_vblnk, d1_hblnk})
    );

// --- ROM DLA GŁOŚNIKA ---
mibombo_rom u_mibombo_rom (
    .clk(clk),
    .addr(mibombo_addr),
    .mibombo_out(mibombo_pixel)
);

// --- LOGIKA POZYCJI (Cykl 0) ---
always_comb begin
    in_neck      = 1'b0;
    in_line      = 1'b0;
    in_mibombo_l = 1'b0;
    in_mibombo_r = 1'b0;
    mibombo_addr = '0;
    hoff_mibombo = '0;
    voff_mibombo = '0;

    // 1. Logika GRYFU i Linii
    if ((vga_in.hcount >= NECK_X && vga_in.hcount < NECK_X + NECK_WIDTH) && 
        (vga_in.vcount >= NECK_Y && vga_in.vcount < NECK_Y + NECK_HEIGHT)) begin
        
        in_neck = 1'b1;

        if (vga_in.hcount == NECK_X || 
            vga_in.hcount == NECK_X + 64 || 
            vga_in.hcount == NECK_X + 128 || 
            vga_in.hcount == NECK_X + 192 || 
            vga_in.hcount == NECK_X + 256 ||
            vga_in.hcount == NECK_X + 320 ||
            vga_in.hcount == NECK_X + 384) begin
            
            in_line = 1'b1;
        end
    end

    // 2. Logika MIBOMBO PRAWEGO
    if ((vga_in.hcount >= MIBOMBO_R_X && vga_in.hcount < MIBOMBO_R_X + MIBOMBO_WIDTH) &&
        (vga_in.vcount >= MIBOMBO_Y && vga_in.vcount < MIBOMBO_Y + MIBOMBO_HEIGHT)) begin
            
        in_mibombo_r = 1'b1;
        hoff_mibombo = 16'(vga_in.hcount - MIBOMBO_R_X);
        voff_mibombo = 16'(vga_in.vcount - MIBOMBO_Y);
        
        mibombo_addr = (voff_mibombo * MIBOMBO_WIDTH) + hoff_mibombo; 
    end

    // 3. Logika MIBOMBO LEWEGO 
    if ((vga_in.hcount >= MIBOMBO_L_X && vga_in.hcount < MIBOMBO_L_X + MIBOMBO_WIDTH) &&
        (vga_in.vcount >= MIBOMBO_Y && vga_in.vcount < MIBOMBO_Y + MIBOMBO_HEIGHT)) begin
            
        in_mibombo_l = 1'b1;
        
        hoff_mibombo = 16'(MIBOMBO_WIDTH - 1 - (vga_in.hcount - MIBOMBO_L_X));
        voff_mibombo = 16'(vga_in.vcount - MIBOMBO_Y);
        
        mibombo_addr = (voff_mibombo * MIBOMBO_WIDTH) + hoff_mibombo; 
    end
end

// --- SYNCHRONIZACJA FLAG (Cykl 1) ---
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        d1_in_neck      <= 1'b0;
        d1_in_line      <= 1'b0;
        d1_in_mibombo_l <= 1'b0;
        d1_in_mibombo_r <= 1'b0;
    end else begin
        d1_in_neck      <= in_neck;
        d1_in_line      <= in_line;
        d1_in_mibombo_l <= in_mibombo_l;
        d1_in_mibombo_r <= in_mibombo_r;
    end
end

// --- ŁĄCZENIE KOLORÓW ---
always_comb begin
    if(d1_hblnk || d1_vblnk) begin
        rgb_nxt = 12'h000;
        
    end else if((d1_in_mibombo_l || d1_in_mibombo_r) && mibombo_pixel != 2'b00) begin 
        if (mibombo_pixel == 2'b01) begin
            rgb_nxt = MIBOMBO_OUTLINE; 
        end else begin
            rgb_nxt = MIBOMBO_INNER; 
        end
    end else if(d1_in_line) begin
        rgb_nxt = LINE_COLOR;
        
    end else if(d1_in_neck) begin
        rgb_nxt = NECK_COLOR;
        
    end else begin 
        rgb_nxt = BG_COLOR;
    end
end

// --- WYJŚCIOWY REJESTR ---
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        rgb_out_song_bg <= '0;
        enable_reg     <= '0;
        enable_song_out <= '0;
    end else begin
        enable_reg <= {enable_reg[0], enable_song_in}; 
        enable_song_out <= enable_reg[1];
        rgb_out_song_bg <= rgb_nxt;
    end
end

endmodule