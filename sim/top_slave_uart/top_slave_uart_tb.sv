module top_slave_uart_tb;

    timeunit 1ns;
    timeprecision 1ps;

    import game_pkg::*;
    import vga_pkg::*;

    logic rst_n, clk40, clk65, write;

    logic [7:0] msg;

    wire logic master_to_slave;

    wire logic enter, esc, song_confirm;
    wire logic [1:0] song_select;
    enum logic [2:0] {INIT, WAIT_CONN, HOME_SCREEN, WAIT_HOMESCREEN, SONG_CHOOSE, PLAY_SONG, ENDSCREEN} state;
    game_if game_engine;

    localparam real CLK_65_PERIOD = 15.3846;     // ok.65 MHz
    localparam real CLK_40_PERIOD = 25.0;

    initial begin
        clk65 = 0;
        forever #(CLK_65_PERIOD/2.0) clk65 = ~clk65;
    end

    initial begin
        clk40 = 0;
        forever #(CLK_40_PERIOD/2.0) clk40 = ~clk40;
    end

    task send(logic [7:0] bajt);
        @(negedge clk40) msg = bajt;
        write = '1;
        @(negedge clk40) write = '0;
        #100us;
    endtask

    initial begin
        rst_n = '0;
        msg = '0;
        write = '0;
        #40ns;
        rst_n = '1;

        // send(ENTER);

        // send(ENTER);
        // send(HALT);

        for(logic [31:0] elapsed = 1; elapsed<=3000; elapsed++) begin
            #1ms;
            $display("%dms elapsed, state = %s", elapsed, state.name());
        end
        $finish;
    end

    uart #(
        .DVSR(22)
    ) master_uart (
        .clk(clk40),
        .reset(!rst_n),
        .tx(master_to_slave),
        .w_data(msg),
        .wr_uart(write)
    );

    top_slave dut(
        .clk(clk65),
        .rst_n,
        .UART_rx(master_to_slave),
        .led({state, song_select, song_confirm, esc, enter, game_engine})
    );

endmodule