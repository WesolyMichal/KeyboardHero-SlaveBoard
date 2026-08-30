/*
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Michał Wesołowski
 *
 * Description:
 * Collects signals from all the fill checkers and colors the pixel accordingly.
 */
import game_pkg::*;
import song_mask_pkg::*;
import vga_pkg::*;

module note_fill_ctl #(
    parameter INV_SCALE = 20,
    parameter MINIMUM_HEIGHT = INV_SCALE * 10
)(
    input logic clk,
    input logic rst_n,
    input logic enable_in,
    
    input logic [31:0] timer,
    input note_t current_note [0:2],

    output logic enable_out,

    input vga_if vga_in,
    output vga_if vga_out
);

logic [15:0] waiting_remaining, duration_remaining;
logic [11:0] rgb_nxt;
logic [31:0] y_scaled;

logic enable_fill, enable_rgb;

logic in_bar [0:2][0:5];

logic [10:0] hcount_del;
note_t current_note_del[0:2];

delay #(
    .CLK_DEL(3),
    .WIDTH(27)
) vga_delay (
    .clk,
    .rst_n,
    .din({enable_in,
          vga_in.hblnk,
          vga_in.hcount,
          vga_in.hsync,
          vga_in.vblnk,
          vga_in.vcount,
          vga_in.vsync}),
    .dout({enable_out,
           vga_out.hblnk,
           vga_out.hcount,
           vga_out.hsync,
           vga_out.vblnk,
           vga_out.vcount,
           vga_out.vsync})
);

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        duration_remaining <= '0;
        waiting_remaining <= '0;
        y_scaled <= '0;
        enable_fill <='0;
    end else begin
        if(timer < current_note[0].waiting) begin
            duration_remaining <= current_note[0].duration;
            waiting_remaining <= current_note[0].waiting - timer;
        end else if(timer < current_note[0].waiting + current_note[0].duration) begin
            duration_remaining <= current_note[0].duration - (timer - current_note[0].waiting);
            waiting_remaining <= '0;
        end else begin
            duration_remaining <= '0;
            waiting_remaining <= '0;
        end

        if (enable_in && vga_in.vcount < NOTE_DISPLAY_HEIGHT) begin

            automatic logic [10:0] y_pixel = NOTE_DISPLAY_HEIGHT - 1 - vga_in.vcount;
            y_scaled <= y_pixel * INV_SCALE;

            enable_fill <= '1;

        end else begin
            y_scaled <= '0;
            enable_fill <= '0;
        end
    end 
end

delay #(
    .CLK_DEL(1),
    .WIDTH(144)
) note_delay(
    .clk,
    .rst_n,
    .din({current_note[0],current_note[1],current_note[2]}),
    .dout({current_note_del[0],current_note_del[1],current_note_del[2]})
);

genvar NOTE_NUM;
genvar COLUMN_NUM;
generate
    for(NOTE_NUM = 0; NOTE_NUM < 3; NOTE_NUM++) begin: consecutive_blk
        for(COLUMN_NUM = 0; COLUMN_NUM < 6; COLUMN_NUM++) begin: column_blk
            fill_checker #(
                .COLUMN(COLUMN_NUM),
                .NOTE_NUM(NOTE_NUM),
                .MINIMUM_HEIGHT(MINIMUM_HEIGHT)
            ) u_fill_checker (
                .clk,
                .rst_n,
                .duration_remaining,
                .waiting_remaining,
                .y_scaled,
                .enable(enable_fill),
                .current_note(current_note_del),
                .in_bar(in_bar[NOTE_NUM][COLUMN_NUM])
            );
        end: column_blk
    end: consecutive_blk
endgenerate

delay #(
    .CLK_DEL(2),
    .WIDTH(12)
) enable_rgb_del (
    .clk,
    .rst_n,
    .din({vga_in.hcount, enable_in}),
    .dout({hcount_del, enable_rgb})
);

always_comb begin
    rgb_nxt = vga_in.rgb;

    if(enable_rgb) begin
        for(logic[2:0] column = '0; column < 6; column++) begin
            if((in_bar[0][column] | in_bar[1][column] | in_bar[2][column])
            && (hcount_del >= COLUMN_XPOS[column] + NOTE_OFFSET)
            && (hcount_del < COLUMN_XPOS[column] + NOTE_OFFSET + NOTE_WIDTH))
            
                rgb_nxt = COLUMN_COLOURS[column];
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        vga_out.rgb <= '0;
    end else begin
        vga_out.rgb <= rgb_nxt;
    end
end

endmodule