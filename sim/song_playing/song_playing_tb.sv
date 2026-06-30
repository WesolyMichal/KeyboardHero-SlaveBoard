module song_playing_tb;

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;

    localparam real CLK_PERIOD = 15.3846;     // ok.65 MHz

    logic clk, rst_n;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2.0) clk = ~clk;
    end

    vga_if vga_tim, vga_out;

    logic [1:0] song_select;
    wire logic final_note;

    logic enable_in;

    vga_timing u_vga_timing(
        .clk,
        .rst_n,
        .vga_out(vga_tim)
    );

    song_mask #(
        .TICK_FREQUENCY(4_000_000)
    ) dut (
        .clk,
        .rst_n,
        .enable_in(enable_in),
        .song_select,
        .vga_in(vga_tim),
        .final_note,
        .vga_out
    );

    initial begin
        rst_n = '0;
        song_select = '0;
        enable_in = '0;

        @(negedge clk) rst_n = '1;

        repeat(10) @(negedge clk);

        enable_in = '1;

        @(posedge final_note);
        $finish;
    end

endmodule