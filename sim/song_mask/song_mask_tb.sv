module song_mask_tb;

timeunit 1ns;
timeprecision 1ps;

// --- Parametry symulacji ---
localparam real CLK_PERIOD = 1000.0 / 65.0;

// --- Parametry VGA 1024x768 @ 60Hz ---
localparam H_DISPLAY = 1024;
localparam H_FP      = 24;
localparam H_SYNC    = 136;
localparam H_BP      = 160;
localparam H_TOTAL   = H_DISPLAY + H_FP + H_SYNC + H_BP; // 1344

localparam V_DISPLAY = 768;
localparam V_FP      = 3;
localparam V_SYNC    = 6;
localparam V_BP      = 29;
localparam V_TOTAL   = V_DISPLAY + V_FP + V_SYNC + V_BP; // 806

// --- Sygnały testowe ---
logic clk;
logic rst_n;
logic enable, enable_song_bg, enable_song_mux;
logic [1:0] song_select;

wire [11:0] rgb_out_song, rgb_out_mask;

// --- Instancja interfejsu VGA ---
vga_if vga_if_timing();
vga_if delay_vga_if();
vga_if vga_if_inst();

// --- Generator zegara ---
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2.0) clk = ~clk;
end

vga_timing u_vga_timing (
    .clk(clk),
    .rst_n(rst_n),
    .hcount(vga_if_timing.hcount),
    .vcount(vga_if_timing.vcount),
    .hsync(vga_if_timing.hsync),
    .vsync(vga_if_timing.vsync),
    .hblnk(vga_if_timing.hblnk),
    .vblnk(vga_if_timing.vblnk)
);

song_bg u_song_bg (
    .clk(clk),
    .rst_n(rst_n),
    .enable_song_in(enable),
    .vga_in(vga_if_timing),
    .rgb_out_song_bg(rgb_out_song), 
    .enable_song_out(enable_song_bg)
);

delay_vga_if u_delay_vga_if (
    .clk(clk),
    .rst_n(rst_n),
    .vga_in(vga_if_timing),
    .delay_vga_out(delay_vga_if)
);

mux_bg u_mux_bg (
    .clk(clk),
    .rst_n(rst_n),
    .enable_song(enable_song_bg),
    .rgb_song(rgb_out_song),
    .delay_vga_in(delay_vga_if),
    .vga_out(vga_if_inst),
    .enable_song_out(enable_song_mux)
);

// --- Instancja DUT (Device Under Test) ---
song_mask dut (
    .clk(clk),
    .rst_n(rst_n),
    .vga_in(vga_if_inst),
    .rgb_out_mask(rgb_out_mask),
    .enable_mask_in(enable_song_mux),
    .song_select(song_select)
);

// --- Główna sekwencja testowa ---
initial begin
    $display("--- Simple Testbench for song_mask started ---");
    
    // 1. Inicjalizacja i reset
    rst_n = 1'b1;
    enable = 0;
    song_select = 0;
    #1;
    rst_n = 1'b0;
    #(CLK_PERIOD * 10);
    rst_n = 1'b1;
    $display("[%0t] Reset finished.", $time);

    // 2. Włączenie modułu i rozpoczęcie testu
    enable = 1;
    song_select = 0;
    $display("[%0t] Top-level enable is ON, playing song 0. Simulation will run for a fixed duration.", $time);

    // 3. Pozwól symulacji działać przez określony czas (np. 2000 klatek)
    // Czas trwania jednej klatki: H_TOTAL * V_TOTAL * CLK_PERIOD
    #17ms;

    // 4. Zakończenie symulacji
    $display("[%0t] Simulation finished.", $time);
    $finish;
end

initial begin
    // Zrzut przebiegów do pliku VCD dla wizualizacji
    $dumpfile("song_mask_tb.vcd");
    $dumpvars(0, song_mask_tb);
end

endmodule
