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
        input  wire clk,
        input  wire btnC,
        input wire btnU, //ESC
        input wire btnD, //ENTER
        input wire btnL, //LEFT
        input wire btnR, //RIGHT
        output wire Vsync,
        output wire Hsync,
        output wire [3:0] vgaRed,
        output wire [3:0] vgaGreen,
        output wire [3:0] vgaBlue,
        output wire [15:0] led,
        input wire JA1
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */

    wire locked;
    wire clk65;
    wire pclk_mirror;
    wire UART_rx;
    wire [3:0] functional_buttons;


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
        .clk_in1(clk),
        .locked,
        .clk_65MHz(clk65)
    );

    


    // Mirror pclk on a pin for use by the testbench;
    // not functionally required for this design to work.

    ODDR pclk_oddr (
        .Q(pclk_mirror),
        .C(clk65),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0)
    );


    /**
     *  Project functional top module
     */

    top_slave u_top_slave (
        .clk(clk65),
        .rst_n(!btnC),
        .UART_rx,
        .r(vgaRed),
        .g(vgaGreen),
        .b(vgaBlue),
        .hs(Hsync),
        .vs(Vsync),
        .led,
        .functional_buttons
    );

    wire esc_button_db, enter_button_db, left_button_db, right_button_db;
    assign functional_buttons = {right_button_db, left_button_db, enter_button_db, esc_button_db};

    debounce debounce_esc (
        .clk(clk65),
        .reset(btnC),
        .sw(btnU),
        .db_level(esc_button_db),
        .db_tick()
    );

    debounce debounce_enter (
        .clk(clk65),
        .reset(btnC),
        .sw(btnD),
        .db_level(enter_button_db),
        .db_tick()
    );

    debounce debounce_left (
        .clk(clk65),
        .reset(btnC),
        .sw(btnL),
        .db_level(),
        .db_tick(left_button_db)
    );

    debounce debounce_right (
        .clk(clk65),
        .reset(btnC),
        .sw(btnR),
        .db_level(),
        .db_tick(right_button_db)
    );

endmodule
