import game_pkg::*;
import vga_pkg::*;

module song_choose_bg_tb;

    timeunit 1ns;
    timeprecision 1ps;

    localparam real CLK_PERIOD = 15.3846;
    localparam RST_START_TIME = 30;
    localparam RST_ACTIVE_TIME = 30;

    logic clk, rst_n;
    logic enable_choose_in;
    logic [2:0] master_song;
    wire [11:0] rgb_out_choose_bg;
    wire enable_choose_out;
    wire [3:0] r, g, b;
    wire vs, hs;

    vga_if vga_tim, vga_tim_del;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2.0) clk = ~clk;
    end

    vga_timing u_vga_timing (
        .clk(clk),
        .rst_n(rst_n),
        .vga_out(vga_tim)
    );

    delay #(
        .CLK_DEL(3),
        .WIDTH(38)
    ) u_delay_vga_tim (
        .clk(clk),
        .rst_n(rst_n),
        .din(vga_tim),
        .dout(vga_tim_del)
    );

    song_choose_bg dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable_choose_in(enable_choose_in),
        .master_song(master_song),
        .vga_in(vga_tim),
        .rgb_out_choose_bg(rgb_out_choose_bg),
        .enable_choose_out(enable_choose_out)
    );

    assign vs = vga_tim_del.vsync;
    assign hs = vga_tim_del.hsync;
    assign r = rgb_out_choose_bg[11:8];
    assign g = rgb_out_choose_bg[7:4];
    assign b = rgb_out_choose_bg[3:0];

    tiff_writer #(
        .XDIM(16'd1344),
        .YDIM(16'd806),
        .FILE_DIR("../../results")
    ) u_tiff_writer (
        .clk(clk),
        .r({r, r}),
        .g({g, g}),
        .b({b, b}),
        .go(vs)
    );

    task automatic capture_song(input logic [2:0] song);
        begin
            master_song = song;
            @(negedge vs);
        end
    endtask

    initial begin
        rst_n = 1'b1;
        enable_choose_in = 1'b0;
        master_song = 3'd0;

        #(RST_START_TIME) rst_n = 1'b0;
        #(RST_ACTIVE_TIME) rst_n = 1'b1;
        enable_choose_in = 1'b1;

        $display("Capturing song choice screen for all song selections.");
        capture_song(3'd0);
        capture_song(3'd1);

        $display("Simulation is over, check the generated image.");
        $finish;
    end

endmodule
