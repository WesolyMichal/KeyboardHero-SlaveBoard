/*
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Jakub Suder
 *
 * Description:
 * Calculating current score and multiplier and holding value of endscore.
 */
import game_pkg::*;

module score_counter (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        enable_song,
    input  game_action  player_action,
    input  logic        action_strobe,
    input  logic        game_active,  

    output logic [23:0] current_score,
    output logic [3:0]  current_multiplier,

    output logic [23:0] end_score
);
    // Parametry
    parameter MAX_MULTIPLIER = 3;
    parameter POINTS_PER_HIT = 1;
    logic [3:0] consecutive_hits;
    logic [3:0] hits_to_next;

    logic score_reset;
    logic enable_song_prev;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        enable_song_prev <= 1'b0;
        score_reset        <= 1'b0;
    end else begin
        score_reset <= 1'b0;
        if (enable_song && !enable_song_prev) begin
            score_reset <= 1'b1;
        end
        enable_song_prev <= enable_song;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_score      <= '0;
        current_multiplier <= 4'd1;
        consecutive_hits   <= '0;
        hits_to_next       <= 4'd15;
        end_score          <= '0;
    end else if (score_reset) begin
        current_score      <= '0;
        current_multiplier <= 4'd1;
        consecutive_hits   <= '0;
        hits_to_next       <= 4'd15;
        end_score          <= '0;
    end else begin
        if (game_active && action_strobe) begin
            if (player_action == HIT) begin
                current_score <= current_score + (POINTS_PER_HIT * current_multiplier);
                if (current_multiplier < MAX_MULTIPLIER) begin
                    if (consecutive_hits + 1 == hits_to_next) begin
                        current_multiplier <= current_multiplier + 1;
                        consecutive_hits   <= '0;
                        hits_to_next       <= 4'd15;
                    end else begin
                        consecutive_hits <= consecutive_hits + 1;
                    end
                end else begin
                    consecutive_hits <= '0;
                end

            end else if (player_action == MISS) begin
                current_multiplier <= 4'd1;
                consecutive_hits   <= '0;
                hits_to_next       <= 4'd15;
            end
        end
        end_score <= current_score;
    end
end
endmodule