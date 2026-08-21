module top_slave_uart_tb;

    timeunit 1ns;
    timeprecision 1ps;

    import game_pkg::*;
    import vga_pkg::*;

    logic rst_n, clk40, clk65, write;

    logic [7:0] msg;

    wire vs, hs;
    wire [3:0] r, g, b;

    logic run_writer;

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

        send(ENTER); //WAIT_CONN -> HOME_SCREEN

        send(ENTER);//HOME_SCREEN -> WAIT_HOMESCREEN -> SONG_CHOOSE
        send({4'b0000, CHOOSE}); //1 song selected
        send({4'b0001, CHOOSE}); //2 song selected
        send({4'b0001, CONFIRM}); //2 song confirmed -> PLAY_SONG
        // send(HALT);

        for(logic [31:0] elapsed = 1; elapsed<=30; elapsed++) begin
            #1ms;
            $display("%dms elapsed, state = %s", elapsed, state.name());
        end
        $finish;
    end

    initial begin
            automatic int unsigned frame_count = 0;
            run_writer = 0;

            forever begin
                @(posedge vs);
                    if(frame_count%5 == 0) begin 
                        run_writer = 1;
                        @(negedge clk65);
                        run_writer = 0;
                    end
                    frame_count++;
        end
    end

    uart #(
        .DVSR(22)
    ) master_uart (
        .clk(clk40),
        .reset(!rst_n),
        .rd_uart(1'b0),
        .wr_uart(write)
    );

    top_slave dut(
        .clk(clk65),
        .rst_n,
        .UART_rx(master_to_slave),
        .led({state, song_select, song_confirm, esc, enter, game_engine}),
        .r,
        .g,
        .b,
        .hs,
        .vs
    );

    tiff_writer #(
        .XDIM(16'd1344),
        .YDIM(16'd806),
        .FILE_DIR("../../results/frames")
    ) u_tiff_writer (
        .clk(clk65),
        .r({r,r}), // fabricate an 8-bit value
        .g({g,g}), // fabricate an 8-bit value
        .b({b,b}), // fabricate an 8-bit value
        .go(run_writer)
    );

endmodule