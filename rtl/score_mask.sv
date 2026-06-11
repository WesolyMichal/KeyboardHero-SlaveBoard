module score_mask (
    input logic clk,
    input logic rst_n,

    vga_if.in  vga_in,
    vga_if.out vga_out,

    input logic enable_score_in,
    output logic enable_score_out,

    // Sygnały z score_countera
    input logic [15:0] current_score,
    input logic [3:0]  current_multiplier
);

// --- PARAMETRY --- 
localparam [11:0] TEXT_COLOR = 12'h3_3_5;
localparam TEXT_SCALE = 2; 
localparam TEXT_ADDR_SHIFT = $clog2(TEXT_SCALE);

// SCORE
localparam SCORE_X = 32;
localparam SCORE_Y = 32;
localparam SCORE_CHARS = 12; 
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
// Sygnały do wyliczeń
logic [3:0] s_4, s_3, s_2, s_1, s_0;
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

// OPÓŹNIONE SYGNAŁY Z INTERFEJSU VGA
logic [10:0] d1_vcount, d1_hcount;
logic        d1_vsync, d1_hsync, d1_vblnk, d1_hblnk;
logic [11:0] d1_rgb;

// --- MODUŁ OPÓŹNIAJĄCY ---
delay #(
    .WIDTH(38), 
    .CLK_DEL(1)
) u_vga_in_del1 (
    .clk(clk),
    .rst_n(rst_n),
    .din({vga_in.vcount, vga_in.hcount, vga_in.vsync, vga_in.hsync, vga_in.vblnk, vga_in.hblnk, vga_in.rgb}),
    .dout({d1_vcount, d1_hcount, d1_vsync, d1_hsync, d1_vblnk, d1_hblnk, d1_rgb})
);

// --- INSTANCJA FONT ROM ---
font_rom u_font_rom (
    .clk(clk),
    .addr(font_addr),
    .char_line_pixels(font_pixels)
);

// --- LOGIKA POZYCJI, ZNAKÓW I WYLICZEŃ (Cykl 0) ---
always_comb begin
    // Wyzerowanie flag na starcie cyklu
    in_score     = 1'b0;
    in_multi     = 1'b0;
    font_addr    = '0;
    char_code    = 8'h20; 
    hoff_text    = '0;
    voff_text    = '0;
    px_h_in_char = '0;
    char_idx     = '0;

    s_4 = (current_score / 10000) % 10;
    s_3 = (current_score / 1000) % 10;
    s_2 = (current_score / 100) % 10;
    s_1 = (current_score / 10) % 10;
    s_0 = current_score % 10;

    m_1 = (current_multiplier / 10) % 10;
    m_0 = current_multiplier % 10;

    // SCORE
    if ((vga_in.hcount >= SCORE_X && vga_in.hcount < SCORE_X + (SCORE_WIDTH << TEXT_ADDR_SHIFT)) && 
        (vga_in.vcount >= SCORE_Y && vga_in.vcount < SCORE_Y + (SCORE_HEIGHT << TEXT_ADDR_SHIFT))) begin
        
        in_score = 1'b1;
        hoff_text = (vga_in.hcount - SCORE_X) >> TEXT_ADDR_SHIFT;
        voff_text = (vga_in.vcount - SCORE_Y) >> TEXT_ADDR_SHIFT;
        char_idx = hoff_text / 8; 

        if (char_idx < 7) char_code = STR_SCORE[char_idx];
        else if (char_idx == 7) char_code = 8'h30 + s_4;
        else if (char_idx == 8) char_code = 8'h30 + s_3;
        else if (char_idx == 9) char_code = 8'h30 + s_2;
        else if (char_idx == 10) char_code = 8'h30 + s_1;
        else char_code = 8'h30 + s_0;

        font_addr = {char_code[6:0], 4'(voff_text[3:0])};
        px_h_in_char = hoff_text[2:0];

    // MULTIPLIER
    end else if ((vga_in.hcount >= MULTI_X && vga_in.hcount < MULTI_X + (MULTI_WIDTH << TEXT_ADDR_SHIFT)) && 
                 (vga_in.vcount >= MULTI_Y && vga_in.vcount < MULTI_Y + (MULTI_HEIGHT << TEXT_ADDR_SHIFT))) begin
        
        in_multi = 1'b1;
        hoff_text = (vga_in.hcount - MULTI_X) >> TEXT_ADDR_SHIFT;
        voff_text = (vga_in.vcount - MULTI_Y) >> TEXT_ADDR_SHIFT;
        char_idx = hoff_text / 8;

        if (char_idx < 8) char_code = STR_MULTI[char_idx];
        else if (char_idx == 8) char_code = 8'h30 + m_1;
        else char_code = 8'h30 + m_0;

        font_addr = {char_code[6:0], 4'(voff_text[3:0])};
        px_h_in_char = hoff_text[2:0];
    end
end

// --- SYNCHRONIZACJA FLAG (Cykl 1) ---
always_ff @(posedge clk, negedge rst_n) begin
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

// --- ŁĄCZENIE KOLORÓW (NAKŁADKA) ---
always_comb begin
    if(d1_hblnk || d1_vblnk) begin
        rgb_nxt = 12'h0_0_0;
        
    end else if (enable_reg[0]) begin
        if((d1_in_score || d1_in_multi) && font_pixels[~d1_px_h_in_char]) begin
            rgb_nxt = TEXT_COLOR;
        end             
    end else begin 
        rgb_nxt = d1_rgb;
    end
end

// --- WYJŚCIOWY REJESTR ---
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        vga_out.vcount   <= '0;
        vga_out.hcount   <= '0;
        vga_out.vsync    <= '0;
        vga_out.hsync    <= '0;
        vga_out.vblnk    <= '0;
        vga_out.hblnk    <= '0;
        vga_out.rgb      <= '0;

        enable_reg       <= '0;
        enable_score_out <= '0;
    end else begin
        enable_reg       <= {enable_reg[0], enable_score_in}; 
        enable_score_out <= enable_reg[1];

        vga_out.vcount   <= d1_vcount;
        vga_out.hcount   <= d1_hcount;
        vga_out.vsync    <= d1_vsync;
        vga_out.hsync    <= d1_hsync;
        vga_out.vblnk    <= d1_vblnk;
        vga_out.hblnk    <= d1_hblnk;
        
        vga_out.rgb      <= rgb_nxt;
    end
end

endmodule