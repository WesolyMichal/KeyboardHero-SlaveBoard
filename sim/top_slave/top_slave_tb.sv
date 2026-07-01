module top_slave_tb;

    timeunit 1ns;
    timeprecision 1ps;
    
        import game_pkg::*;
        import vga_pkg::*;
    
        logic rst_n, clk;
    
        localparam real CLK_PERIOD = 15.3846;     // ok.65 MHz
    
        initial begin
            clk = 0;
            forever #(CLK_PERIOD/2.0) clk = ~clk;
        end
    
        /*
         * input signals
         */
    
        logic [7:0] r_data;
        logic read_data;
    
        /*
         * inter-module signals
         */
    
        vga_if vga_out;        
    
        /*
         * output signals
         */
    
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
    
        initial begin
            rst_n = '0;
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
            send(HALT);
            repeat(20) @(negedge clk);
    
            send(ENTER);
            send_choose(2);
            send_confirm(1);
            repeat(20) @(negedge clk);
    
            send(HALT);
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
            send_game(.buttons(6'b0), .status(PLAYER_IDLE));

            repeat(20) @(negedge clk);
            $finish;
        end
    
        top_slave_4test dut(
            .clk,
            .rst_n,
            .r_data,
            .read_data,
            .vga_out
        );
    
    endmodule