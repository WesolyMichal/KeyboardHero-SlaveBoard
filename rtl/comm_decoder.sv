import game_pkg::*;

module comm_decoder(
    input logic clk,
    input logic rst_n,

    input logic [7:0] rx_data,
    input logic read_data,

    input logic game_enable,

    output logic song_choosing,
    output logic song_confirm,

    output game_pkg::game_if game_engine,
    output logic enter,
    output logic esc,

    output logic [1:0] song_select
);

logic enter_nxt, esc_nxt, song_choosing_nxt, song_confirm_nxt;
logic [1:0] song_select_nxt;
game_if game_engine_buffer, game_engine_buffer_nxt, game_engine_nxt;

always_ff @(negedge rst_n or posedge clk) begin
    if(!rst_n) begin
        enter <= '0;
        esc <= '0;
        song_choosing <= '0;
        song_confirm <= '0;
        song_select <= '0;
        game_engine <= '0;
        game_engine_buffer <= '0;
    end else begin
        enter <= enter_nxt;
        esc <= esc_nxt;
        song_choosing <= song_choosing_nxt;
        song_confirm <= song_confirm_nxt;
        song_select <= song_select_nxt;
        game_engine <= game_engine_nxt;
        game_engine_buffer <= game_engine_buffer_nxt;
    end
end

always_comb begin
    enter_nxt = '0;
    esc_nxt = '0;
    song_choosing_nxt = song_choosing;
    song_confirm_nxt = song_confirm;
    song_select_nxt = song_select;
    game_engine_buffer_nxt = game_engine_buffer;

    if(read_data) begin
        song_choosing_nxt = 1'b0;
        song_confirm_nxt = 1'b0;

        casex(rx_data)
            HALT: esc_nxt = 1'b1;
            ENTER: enter_nxt = 1'b1;
            {4'b00xx, CHOOSE}: begin
                song_select_nxt = rx_data[5:4];
                song_choosing_nxt = 1'b1;
            end
            {4'b00xx, CONFIRM}: begin
                song_select_nxt = rx_data[5:4];
                song_confirm_nxt = 1'b1;
            end
        endcase

        game_engine_buffer_nxt.buttons = rx_data[7:2];
        game_engine_buffer_nxt.status = rx_data[1:0];
    end

end

assign game_engine_nxt = (game_enable) ? game_engine_buffer : game_engine;

endmodule