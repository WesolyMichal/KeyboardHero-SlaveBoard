module slave_FSM_tb;

timeunit 1ns;
timeprecision 1ps;

    import game_pkg::*;

    logic rst_n, clk;

    localparam real CLK_PERIOD = 15.3846;     // ok.65 MHz

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2.0) clk = ~clk;
    end

    /*
     * input signals
     */
    
    logic final_note;

    logic [7:0] r_data;
    logic read_data;

    /*
     * inter-module signals
     */

    wire logic song_choosing, song_confirm;
    wire logic enter, esc;

    game_if game_engine;
    logic [1:0] master_song_select;
    

    /*
     * output signals
     */

    wire logic [1:0] master_song;
    enable_bgs enable_bgs_FSM;
    wire logic enter_out;

    task send(logic [7:0] msg);
        @(negedge clk) r_data = msg;
        read_data = '1;
        @(negedge clk) read_data = '0;
    endtask

    task send_choose(logic [1:0] song);
        send({2'b00, song, CHOOSE});
    endtask

    task send_confirm(logic [1:0] song);
        send({2'b00, song, CONFIRM});
    endtask

    task send_game(logic[5:0] buttons, game_action status);
        game_if game;
        game.buttons = buttons;
        game.status = status;
        send(game);
    endtask

    task end_game;
        @(negedge clk) final_note = '1;
        @(negedge clk) final_note = '0;
    endtask

    initial begin
        rst_n = '0;
        final_note = '0;
        read_data = '0;
        r_data = '0;
        repeat(5) @(negedge clk);
        rst_n = '1;

        send(ENTER);
        repeat(5) @(negedge clk);
        send(ENTER);
        repeat(20) @(negedge clk);
        send_choose(0);
        send_choose(1);
        send_choose(2);
        send_choose(3);
        repeat(5) @(negedge clk);
        send(ESC);
        repeat(5) @(negedge clk);

        send(ENTER);
        send_choose(2);
        send_confirm(1);
        repeat(20) @(negedge clk);

        send(ESC);
        repeat(5) @(negedge clk);

        send(ENTER);
        send_choose(2);
        send_confirm(1);
        repeat(20) @(negedge clk);

        send_game(.buttons(0), .status(END_GAME));
        repeat(5) @(negedge clk);

        send(ENTER);
        send_choose(2);
        send_confirm(1);
        repeat(20) @(negedge clk);

        end_game;

        $finish;
    end

    comm_decoder u_comm_decoder(
        .clk,
        .rst_n,
        .enter,
        .esc,
        .r_data,
        .read_data,
        .song_choosing,
        .song_confirm,
        .game_enable(enable_bgs_FSM.enable_song),
        .game_engine,
        .song_select(master_song_select)
    );

    slave_FSM dut(
        .clk,
        .rst_n,
        .esc,
        .enter,
        .song_choosing,
        .song_confirm,
        .master_song_select,
        .master_song,
        .enable_bgs_FSM,
        .final_note,
        .enter_out,
        .status(game_engine.status)
    );

endmodule