import vga_pkg::*;

module mux_bg (
    input logic clk,
    input logic rst_n,

    input game_pkg::enable_bgs enable_from_bg,

    input logic [11:0] rgb_start,
    input logic [11:0] rgb_choose,
    input logic [11:0] rgb_song,
    input logic [11:0] rgb_endscreen,

    input vga_if delay_vga_in,
    output logic enable_song_out,
    output vga_if vga_out
);

logic [11:0] rgb_nxt;
logic enable_song_out_next;

always_ff @(posedge clk) begin
    if(!rst_n) begin
        vga_out.vcount <= '0;
        vga_out.vsync  <= '0;
        vga_out.vblnk  <= '0;
        vga_out.hcount <= '0;
        vga_out.hsync  <= '0;
        vga_out.hblnk  <= '0;
        vga_out.rgb    <= '0;
        enable_song_out <= '0;
    end else begin
        vga_out.vcount <= delay_vga_in.vcount;
        vga_out.vsync  <= delay_vga_in.vsync ;
        vga_out.vblnk  <= delay_vga_in.vblnk ;
        vga_out.hcount <= delay_vga_in.hcount ;
        vga_out.hsync  <= delay_vga_in.hsync ;
        vga_out.hblnk  <= delay_vga_in.hblnk ;
        vga_out.rgb    <= rgb_nxt;
        enable_song_out <= enable_song_out_next;
    end
end

always_comb begin
    enable_song_out_next = 0;
    case(enable_from_bg)
        4'b0001: rgb_nxt = rgb_endscreen;
        4'b0010: begin
                    rgb_nxt = rgb_song;
                    enable_song_out_next = 1;
                end
        4'b0100: rgb_nxt = rgb_choose;
        4'b1000: rgb_nxt = rgb_start;
        default: rgb_nxt = '0;
    endcase
end

endmodule