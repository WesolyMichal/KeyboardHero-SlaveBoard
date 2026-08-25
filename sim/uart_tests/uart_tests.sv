module uart_tests_tb;

    timeunit 1ns;
    timeprecision 1ps;

    import game_pkg::*;

    logic rst_n;
    logic clk40;
    logic clk65;
    logic write;
    logic [7:0] msg;

    logic master_to_slave;
    logic [7:0] slave_r_data;
    logic slave_rd_uart;
    logic slave_rx_empty;
    logic [7:0] received_data;
    logic received_data_ready;

    localparam real CLK40_PERIOD = 25.0;
    localparam real CLK65_PERIOD = 15.3846;

    initial begin
        clk40 = 1'b0;
        forever #(CLK40_PERIOD / 2.0) clk40 = ~clk40;
    end

    initial begin
        clk65 = 1'b0;
        forever #(CLK65_PERIOD / 2.0) clk65 = ~clk65;
    end

    task automatic send(input logic [7:0] data);
        @(negedge clk40);
        msg = data;
        write = 1'b1;
        @(negedge clk40);
        write = 1'b0;
        // 8N1 frame at approximately 115200 baud.
        #120us;
    endtask

    initial begin
        rst_n = 1'b0;
        write = 1'b0;
        msg = 8'h00;

        #40ns;
        rst_n = 1'b1;

        send(ENTER);
        @(posedge received_data_ready);
        if (received_data !== ENTER)
            $fatal(1, "UART test failed: expected 0x%02h, received 0x%02h", ENTER, received_data);

        $display("PASS: direct UART TX 40 MHz -> RX 65 MHz delivered 0x%02h", received_data);
        $finish;
    end

    initial begin
        #2ms;
        $fatal(1, "UART test timeout: no complete byte received");
    end

    uart #(
        .DVSR(22)
    ) master_uart (
        .clk(clk40),
        .reset(!rst_n),
        .rd_uart(1'b0),
        .wr_uart(write),
        .rx(1'b1),
        .w_data(msg),
        .tx_full(),
        .rx_empty(),
        .r_data(),
        .tx(master_to_slave),
        .tx_empty_out()
    );

    uart #(
        .DVSR(36)
    ) slave_uart (
        .clk(clk65),
        .reset(!rst_n),
        .rd_uart(slave_rd_uart),
        .wr_uart(1'b0),
        .rx(master_to_slave),
        .w_data(8'h00),
        .tx_full(),
        .rx_empty(slave_rx_empty),
        .r_data(slave_r_data),
        .tx(),
        .tx_empty_out()
    );

    uart_reader u_uart_reader (
        .clk(clk65),
        .rst_n,
        .rx_empty(slave_rx_empty),
        .rd_uart(slave_rd_uart),
        .r_data(slave_r_data),
        .out_data(received_data),
        .data_ready(received_data_ready)
    );

endmodule
