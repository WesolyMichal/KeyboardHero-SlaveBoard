import game_pkg::*;

module top_bg_tb;

timeunit 1ns;
timeprecision 1ps;

// --- Parametry symulacji ---
localparam real CLK_PERIOD = 15.3846;     // ok.65 MHz
localparam RST_START_TIME = 30;
localparam RST_ACTIVE_TIME = 30;

// --- Sygnały testowe ---
logic clk;
logic rst_n;
wire vs, hs;
wire [3:0] r, g, b;
logic [7:0] button;
logic [15:0] score_in;
logic enable_start, enable_song_choose, enable_song, enable_endscreen;


// --- Instancja interfejsu VGA ---
vga_if vga_if_timing;
vga_if vga_if_out_dut;
vga_if vga_if_inst;

// --- Generator zegara ---
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2.0) clk = ~clk;
end

vga_timing u_vga_timing (
    .clk(clk),
    .rst_n(rst_n),
    .vga_out(vga_if_timing)
);


// --- Instancja DUT (Device Under Test) ---
top_bg dut (
    .clk(clk),
    .rst_n(rst_n),
    .button(button),
    .score_in(score_in),
    .enable_start(enable_start),
    .enable_song_choose(enable_song_choose),
    .enable_song(enable_song),
    .enable_endscreen(enable_endscreen),
    .vga_in(vga_if_timing),
    .vga_out(vga_if_out_dut)
);

assign vs = vga_if_out_dut.vsync;
assign hs = vga_if_out_dut.hsync;
assign r = vga_if_out_dut.rgb[11:8];
assign g = vga_if_out_dut.rgb[7:4];
assign b = vga_if_out_dut.rgb[3:0];

// --- Logika zapisu TIFF ---
logic tiff_go;
// Bramkujemy zegar tak, aby tiff_writer widział tylko aktywne piksele (bez blankingu)
wire tiff_clk = clk | vga_if_out_dut.hblnk | vga_if_out_dut.vblnk;

tiff_writer #(
        .XDIM(16'd1024),
        .YDIM(16'd768),
        .FILE_DIR("../../results")
    ) u_tiff_writer (
        .clk(tiff_clk),
        .r({r,r}), // fabricate an 8-bit value
        .g({g,g}), // fabricate an 8-bit value
        .b({b,b}), // fabricate an 8-bit value
        .go(tiff_go)
    );

// Task do przechwycenia jednej klatki obrazu
task capture_frame;
    begin
        @(negedge vga_if_out_dut.vblnk); // Czekaj na start obszaru aktywnego klatki
        tiff_go = 1; #1 tiff_go = 0;    // Start zapisu
        @(posedge vga_if_out_dut.vblnk); // Czekaj na koniec obszaru aktywnego
        tiff_go = 1; #1 tiff_go = 0;    // Koniec zapisu
        @(posedge vga_if_out_dut.vblnk); // Dodatkowy czas na zamknięcie pliku
    end
endtask

// --- Symulacja ---
initial begin
    // Reset
    enable_start = 0;
    enable_song_choose = 0;
    enable_song = 0;
    enable_endscreen = 0;
    score_in = 0;
    button = 0;
    tiff_go = 0;

    rst_n = 1;
    #(RST_START_TIME) rst_n = 1'b0;
    #(RST_ACTIVE_TIME) rst_n = 1'b1;

    // 1. Start BG (Standardowy)
    enable_start = 1;
    capture_frame();

    // 2. Start BG (Wciśnięty Enter)
    button = game_pkg::ENTER;
    capture_frame();
    button = 0;

    // 3. Choose Song BG
    enable_start = 0; enable_song_choose = 1;
    capture_frame();

    // 4. Song BG
    enable_song_choose = 0; enable_song = 1;
    capture_frame();

    // 5. Endscreen BG (Score: 1234)
    enable_song = 0; enable_endscreen = 1;
    score_in = 16'h1234;
    capture_frame();

    // 6. Endscreen BG (Score: ABCD)
    score_in = 16'hABCD;
    capture_frame();

    $finish;
end

endmodule