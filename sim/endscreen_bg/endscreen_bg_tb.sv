module endscreen_bg_tb;

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
    logic [15:0] endscore;
    wire [11:0] rgb_out_endscreen_bg;

    logic enable_endscreen_in, enable_endscreen_out;


    /**
     * Clock generation
     */

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2.0) clk = ~clk;
    end

    //inicjalizacja interface in i out
    vga_if vga_in_if();
    vga_if vga_out_if();
    vga_if vga_in_bez_rgb_if();
    vga_if vga_out_bez_rgb_if();

    

    /**
     * Submodules instances
     */
    vga_timing u_vga_timing (
        .clk(clk),
        .rst_n(rst_n),
        .vcount(vga_in_bez_rgb_if.vcount),
        .vsync(vga_in_bez_rgb_if.vsync),
        .vblnk(vga_in_bez_rgb_if.vblnk),
        .hcount(vga_in_bez_rgb_if.hcount),
        .hsync(vga_in_bez_rgb_if.hsync),
        .hblnk(vga_in_bez_rgb_if.hblnk)
    );

    delay_vga_if u_delay_vga_if (
        .clk(clk),
        .rst_n(rst_n),
        .vga_in(vga_in_bez_rgb_if),
        .delay_vga_out(vga_out_bez_rgb_if)
    );

    endscreen_bg dut (
        .clk(clk),
        .rst_n(rst_n),
        .vga_in(vga_in_bez_rgb_if.in),
        .rgb_out_endscreen_bg(rgb_out_endscreen_bg),
        .end_score_in(endscore),
        .enable_endscreen_in(enable_endscreen_in),
        .enable_endscreen_out(enable_endscreen_out)
    );

    assign vs = vga_out_bez_rgb_if.vsync;
    assign hs = vga_out_bez_rgb_if.hsync;
    assign r = rgb_out_endscreen_bg[11:8];
    assign g = rgb_out_endscreen_bg[7:4];
    assign b = rgb_out_endscreen_bg[3:0];

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
        endscore = 300;
        #(RST_START_TIME) rst_n = 1'b0;
        #(RST_ACTIVE_TIME) rst_n = 1'b1;

        enable_endscreen_in = 1'b1;

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
