import vga_pkg::*;

module start_bg_tb;

    timeunit 1ns;
    timeprecision 1ps;

    /**
     *  Local parameters
     */

    localparam real CLK_PERIOD = 15.3846;     // ok.65 MHz
    localparam RST_START_TIME = 30;
    localparam RST_ACTIVE_TIME = 30;


    /**
     * Local variables and signals
     */

    logic clk, rst_n;
    wire vs, hs;
    wire [3:0] r, g, b;
    wire [11:0] rgb_out_bg;

    logic enable_in, enable_out;

    logic enter;

    /**
     * Clock generation
     */

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2.0) clk = ~clk;
    end

    //inicjalizacja interface in i out
    vga_if vga_tim, vga_tim_del, vga_bg;

    /**
     * Submodules instances
     */
    vga_timing u_vga_timing (
        .clk(clk),
        .rst_n(rst_n),
        .vga_out(vga_tim)
    );

    delay #(
        .CLK_DEL(2),
        .WIDTH(38)
    ) u_delay_vga_tim (
        .clk(clk),
        .rst_n(rst_n),
        .din(vga_tim),
        .dout(vga_tim_del)
    );

    start_bg dut(
        .clk,
        .rst_n,
        .enable_start_in(enable_in),
        .enable_start_out(enable_out),
        .rgb_out_start_bg(rgb_out_bg),
        .vga_in(vga_tim),
        .enter
    );

    assign vs = vga_tim_del.vsync;
    assign hs = vga_tim_del.hsync;
    assign r = rgb_out_bg[11:8];
    assign g = rgb_out_bg[7:4];
    assign b = rgb_out_bg[3:0];

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


    /**
     * Main test
     */

    initial begin
        rst_n = 1'b1;
        enter = 1'b1;

        #(RST_START_TIME) rst_n = 1'b0;
        #(RST_ACTIVE_TIME) rst_n = 1'b1;

        enable_in = 1'b1;

        $display("If simulation ends before the testbench");
        $display("completes, use the menu option to run all.");
        $display("Prepare to wait a long time...");

        wait (vs == 1'b0);
        @(negedge vs) $display("Info: negedge VS at %t",$time);
        @(negedge vs) $display("Info: negedge VS at %t",$time);

        // End the simulation.
        $display("Simulation is over, check the waveforms.");
        $finish;
    end

endmodule
