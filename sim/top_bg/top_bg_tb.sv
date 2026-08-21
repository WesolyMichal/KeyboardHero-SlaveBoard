import game_pkg::*;
import vga_pkg::*;

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
logic enter_in_FSM;
logic [1:0] master_song;
logic [15:0] score_in;
enable_bgs enable_backgrounds;

wire logic enable_song;

// --- Instancja interfejsu VGA ---
vga_if vga_if_out_dut;

// --- Generator zegara ---
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2.0) clk = ~clk;
end

// --- Instancja DUT (Device Under Test) ---
top_bg dut (
    .clk,
    .rst_n,
    .enable_backgrounds,
    .enable_song,
    .enter_in_FSM,
    .master_song,
    .score_in,
    .vga_out(vga_if_out_dut)
);

assign vs = vga_if_out_dut.vsync;
assign hs = vga_if_out_dut.hsync;
assign r = vga_if_out_dut.rgb[11:8];
assign g = vga_if_out_dut.rgb[7:4];
assign b = vga_if_out_dut.rgb[3:0];

// --- Logika zapisu TIFF ---
// Bramkujemy zegar tak, aby tiff_writer widział tylko aktywne piksele (bez blankingu)

tiff_writer #(
    .XDIM(16'd1344),
    .YDIM(16'd806),
    .FILE_DIR("../../results")
) u_tiff_writer (
    .clk(clk),
    .r({r,r}), // fabricate an 8-bit value
    .g({g,g}), // fabricate an 8-bit value
    .b({b,b}), // fabricate an 8-bit value
    .go(vs)
);

// Task do przechwycenia jednej klatki obrazu
task capture_frame;
        @(negedge vs);
endtask

// --- Symulacja ---
initial begin
    // Reset
    enable_backgrounds = '0;
    score_in = 0;
    enter_in_FSM = 0;
    master_song = '0;

    rst_n = 1;
    #(RST_START_TIME) rst_n = 1'b0;
    #(RST_ACTIVE_TIME) rst_n = 1'b1;

    // 1. Start BG (Standardowy)
    enable_backgrounds.enable_start = 1;
    capture_frame();

    // 2. Start BG (Wciśnięty Enter)
    enter_in_FSM = '1;
    capture_frame();
    enter_in_FSM = '0;

    // 3. Choose Song BG
    enable_backgrounds.enable_start = 0; enable_backgrounds.enable_song_choose = 1;
    capture_frame();

    // 4. Song BG
    enable_backgrounds.enable_song_choose = 0; enable_backgrounds.enable_song = 1;
    capture_frame();

    // 5. Endscreen BG (Score: 1234)
    enable_backgrounds.enable_song = 0; enable_backgrounds.enable_endscreen = 1;
    score_in = 16'h1234;
    capture_frame();

    // 6. Endscreen BG (Score: ABCD)
    score_in = 16'hABCD;
    capture_frame();

    $finish;
end

endmodule