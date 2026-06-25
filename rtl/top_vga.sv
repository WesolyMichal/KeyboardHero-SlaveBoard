module top_vga (
        input  logic clk,
        input  logic rst_n,
        output logic vs,
        output logic hs,
        output logic [3:0] r,
        output logic [3:0] g,
        output logic [3:0] b
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */

    // VGA signals from timing
    wire vga_if vga_tim;

    // VGA signals from background
    wire vga_if vga_bg;


    /**
     * Signals assignments
     */

    assign vs = vga_bg.vsync;
    assign hs = vga_bg.hsync;
    assign {r,g,b} = vga_bg.rgb;


    /**
     * Submodules instances
     */

    vga_timing u_vga_timing (
        .clk,
        .rst_n,
        .vga_out(vga_tim)
    );


endmodule
