module start_bg (
    input logic clk,
    input logic rst_n,

    vga_if.in vga_in,
    vga_if.out vga_out,

    input logic [7:0] button
);

import buttons_pkg::*;

// --- PARAMETRY --- 
localparam [11:0] BG_COLOR = 12'h3_3_5;
localparam LOGO_X = 0;
localparam LOGO_Y = 640;
localparam LOGO_LENGTH = 48; // X (horyzontalnie) -> 6 bitów
localparam LOGO_WIDTH  = 64; // Y (wertykalnie)   -> 6 bitów
localparam LOGO_SCALE = 2; //tylko potegi 2
localparam LOGO_ADDR_SHIFT = $clog2(LOGO_SCALE);

localparam ENTER_X = 384;
localparam ENTER_Y = 426;
localparam ENTER_LENGTH = 128; // X (horyzontalnie) -> 7 bitów
localparam ENTER_WIDTH  = 64;  // Y (wertykalnie)   -> 6 bitów
localparam ENTER_SCALE = 2; //tylko potegi 2
localparam ENTER_ADDR_SHIFT = $clog2(ENTER_SCALE);

localparam TEXT_X = 96;
localparam TEXT_Y = 200;
localparam TEXT_LENGTH = 13; 
localparam TEXT_WIDTH  = TEXT_LENGTH*8;
localparam TEXT_HEIGHT = 16;
localparam TEXT_SCALE = 8; //tylko potegi 2
localparam TEXT_ADDR_SHIFT = $clog2(TEXT_SCALE);

localparam logic [0:TEXT_LENGTH-1] [7:0] TEXT = "Keyboard-Hero";

// --- SYGNAŁY WEWNĘTRZNE ---
logic [11:0] rgb_nxt;

logic [6:0] voff_text;
logic [7:0] hoff_text;
logic [7:0] char_code;
logic [2:0] px_h_in_char, d1_px_h_in_char;

// Flagi kombinacyjne + opuznione
logic in_logo, in_button, d1_in_logo, d1_in_button;
logic in_text, d1_in_text;

// Pamięci ROM
logic [11:0] logo_addr, logo_rgb;
logic [12:0] enter_addr;
logic enter_bit;

logic [10:0] font_addr;
logic [7:0] font_pixels;

// SYGNAŁY OPÓŹNIONE Z MODUŁU DELAY
logic [10:0] d1_vcount, d1_hcount;
logic        d1_vsync, d1_hsync, d1_vblnk, d1_hblnk;

delay  #(
        .WIDTH(26), 
        .CLK_DEL(1)
    )u_vga_in_del1(
        .clk,
        .rst_n,
        .din({vga_in.vcount, vga_in.hcount, vga_in.vsync, vga_in.hsync, vga_in.vblnk, vga_in.hblnk}),
        .dout({d1_vcount, d1_hcount, d1_vsync, d1_hsync, d1_vblnk, d1_hblnk})
    );

// Instancje ROM
agh_image_rom u_agh_image_rom (
    .clk,
    .address(logo_addr),
    .rgb(logo_rgb)
);

enter_button_rom u_enter_button_rom  (
     .clk,
     .rom_addr(enter_addr),
     .enter_pixel_bit(enter_bit)
 );

 font_rom u_font_rom (
    .clk,
    .addr(font_addr),
    .char_line_pixels(font_pixels)
 );

// Drivowanie rom
always_comb begin
    logo_addr = '0;
    enter_addr = '0;
    in_logo = 1'b0;
    in_button = 1'b0;
    in_text = 1'b0;
    font_addr = '0;
    char_code = '0;
    px_h_in_char = '0;

    // Logika ENTER
    if((vga_in.hcount >= ENTER_X && vga_in.vcount >= ENTER_Y) && 
       (vga_in.hcount < ENTER_X + (ENTER_LENGTH*ENTER_SCALE) && vga_in.vcount < ENTER_Y + (ENTER_WIDTH*ENTER_SCALE))) begin
        in_button = 1'b1;
        enter_addr = { 6'((vga_in.vcount - ENTER_Y) >> ENTER_ADDR_SHIFT), 7'((vga_in.hcount - ENTER_X) >> ENTER_ADDR_SHIFT) };
    end

    // Logika LOGO
    if((vga_in.hcount >= LOGO_X && vga_in.vcount >= LOGO_Y) && 
       (vga_in.hcount < LOGO_X + (LOGO_LENGTH*LOGO_SCALE) && vga_in.vcount < LOGO_Y + (LOGO_WIDTH*LOGO_SCALE))) begin
        in_logo = 1'b1;
        logo_addr = { 6'((vga_in.vcount - LOGO_Y)>>LOGO_ADDR_SHIFT), 6'((vga_in.hcount - LOGO_X)>>LOGO_ADDR_SHIFT) };
    end

    // Logika TEXT
    if((vga_in.hcount >= TEXT_X && vga_in.hcount < TEXT_X + (TEXT_WIDTH << TEXT_ADDR_SHIFT)) && 
       (vga_in.vcount >= TEXT_Y && vga_in.vcount < TEXT_Y + (TEXT_HEIGHT << TEXT_ADDR_SHIFT))) begin
        in_text = 1'b1;
        hoff_text = (vga_in.hcount - TEXT_X) >> TEXT_ADDR_SHIFT;
        voff_text = (vga_in.vcount - TEXT_Y) >> TEXT_ADDR_SHIFT;
    
        char_code = TEXT[ hoff_text / 8 ]; 
        // adres dla modułu font_rom (kod ASCII + numer wiersza od 0 do 15)
        font_addr = { char_code[6:0], 4'(voff_text[3:0]) };
        px_h_in_char = hoff_text[2:0];
    end

end

// Synchronizacja flag
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        d1_in_logo   <= 1'b0;
        d1_in_button <= 1'b0;
        d1_in_text <= 1'b0;
        d1_px_h_in_char <= '0;
    end else begin
        d1_in_logo   <= in_logo;
        d1_in_button <= in_button;
        d1_in_text <= in_text;
        d1_px_h_in_char <= px_h_in_char;
    end
end

// Łączenie kolorów 
always_comb begin
    if(d1_hblnk || d1_vblnk) begin //blank
        rgb_nxt = 12'h000;
    end else if(d1_in_logo) begin //logo
        rgb_nxt = logo_rgb;
    end else if(d1_in_button) begin //enter
        rgb_nxt = enter_bit ? 12'hf_f_f : 12'h0_0_0;
        if (button == BTN_ENTER)
            rgb_nxt = ~rgb_nxt;
    end else if(d1_in_text && font_pixels[~d1_px_h_in_char]) begin //text
        rgb_nxt = 12'hf_f_0;
    end else begin  //tło 
        rgb_nxt = BG_COLOR;
    end
end

// Wyściowy rejestr
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        vga_out.vcount <= '0;
        vga_out.vsync  <= '0;
        vga_out.vblnk  <= '0;
        vga_out.hcount <= '0;
        vga_out.hsync  <= '0;
        vga_out.hblnk  <= '0;
        vga_out.rgb    <= '0;
    end else begin
        vga_out.vcount  <= d1_vcount;
        vga_out.hcount  <= d1_hcount;
        vga_out.vsync   <= d1_vsync;
        vga_out.hsync   <= d1_hsync; 
        vga_out.vblnk   <= d1_vblnk;
        vga_out.hblnk   <= d1_hblnk;

        vga_out.rgb     <= rgb_nxt;
    end
end

endmodule