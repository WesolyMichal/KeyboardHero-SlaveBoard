/**
 * San Jose State University
 * EE178 Lab #4
 * Author: prof. Eric Crabilla
 *
 * Modified by:
 * 2025  AGH University of Science and Technology
 * MTM UEC2
 * Piotr Kaczmarczyk
 *
 * Description:
 * Top level synthesizable module including the project top and all the FPGA-referred modules.
 */

module top_vga_basys3 (
        input  wire clk_in1,
        input  wire btnC,
        output wire Vsync,
        output wire Hsync,
        output wire [3:0] vgaRed,
        output wire [3:0] vgaGreen,
        output wire [3:0] vgaBlue,
        input wire JA1
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */

    wire locked;
    wire pclk;
    wire pclk_mirror;
    wire UART_rx;

    (* KEEP = "TRUE" *)
    (* ASYNC_REG = "TRUE" *)
    logic [7:0] safe_start = 0;
    // For details on synthesis attributes used above, see AMD Xilinx UG 901:
    // https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/Synthesis-Attributes


    /**
     * Signals assignments
     */

    assign UART_rx = JA1;


    /**
     * FPGA submodules placement
     */

    clk_wiz_0 u_clk_wiz (
        .clk_in1(clk_in1),
        .locked,
        .clk_65MHz(pclk)
    );

    


    // Mirror pclk on a pin for use by the testbench;
    // not functionally required for this design to work.

    ODDR pclk_oddr (
        .Q(pclk_mirror),
        .C(pclk),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0)
    );


    /**
     *  Project functional top module
     */

    // bg_testing u_top_vga (
    //     .clk(pclk),
    //     .rst_n(!btnC),
    //     // .UART_rx(JA1),
    //     .r(vgaRed),
    //     .g(vgaGreen),
    //     .b(vgaBlue),
    //     .hs(Hsync),
    //     .vs(Vsync)
    // );

    top_slave u_top_slave (
        .clk(pclk),
        .rst_n(!btnC),
        .UART_rx,
        .r(vgaRed),
        .g(vgaGreen),
        .b(vgaBlue),
        .hs(Hsync),
        .vs(Vsync)
    );

endmodule
