module song_mask_tb;

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;

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

    logic enable_in, enable_song_mask;


    /**
     * Clock generation
     */

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2.0) clk = ~clk;
    end

    //inicjalizacja interface in i out
    vga_if vga_tim, vga_tim_del, vga_mask;

    vga_if vga_out; 

    /*
     * Inicjalizacja wejsc
     */

    logic [7:0] note_addr;
    logic [1:0] song_select;
    logic [31:0] timer;

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
    ) delay_vga (
        .clk,
        .rst_n,
        .din(vga_tim),
        .dout(vga_tim_del)
    );

    song_bg u_song_bg(
        .clk,
        .rst_n,
        .enable_song_in(enable_in),
        .enable_song_out(enable_song_mask),
        .rgb_out_song_bg(rgb_out_bg),
        .vga_in(vga_tim)
    );

    always_comb begin
        vga_mask = vga_tim_del;
        vga_mask.rgb = rgb_out_bg;
    end

    song_mask4test dut(
        .clk,
        .rst_n,
        .vga_in(vga_mask),
        .vga_out,
        .enable_mask_in(enable_song_mask),
        .note_addr,
        .song_select,
        .timer
    );

    assign vs = vga_out.vsync;
    assign hs = vga_out.hsync;
    assign r = vga_out.rgb[11:8];
    assign g = vga_out.rgb[7:4];
    assign b = vga_out.rgb[3:0];

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
        
        #(RST_START_TIME) rst_n = 1'b0;

        song_select = 2'd0;
        timer = 32'h0500;
        note_addr = 8'h00;

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
