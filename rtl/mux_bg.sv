module mux_bg (
    input logic clk,
    input logic rst_n,

    input logic enable_start,
    input logic [11:0] rgb_start,
    input logic enable_song_choose,
    input logic [11:0] rgb_choose,
    input logic enable_song,
    input logic [11:0] rgb_song,
    input logic enable_endscreen,
    input logic [11:0] rgb_endscreen,

    vga_if.in_bez_rgb delay_vga_in,

    vga_if.out vga_out
);

logic [11:0] rgb_nxt;
logic [3:0] enable_addres;

always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        vga_out.vcount <= '0;
        vga_out.vsync  <= '0;
        vga_out.vblnk  <= '0;
        vga_out.hcount <= '0;
        vga_out.hsync  <= '0;
        vga_out.hblnk  <= '0;
        vga_out.rgb    <= '0;
    end else begin
        vga_out.vcount <= delay_vga_in.vcount;
        vga_out.vsync  <= delay_vga_in.vsync ;
        vga_out.vblnk  <= delay_vga_in.vblnk ;
        vga_out.hcount <= delay_vga_in.hcount ;
        vga_out.hsync  <= delay_vga_in.hsync ;
        vga_out.hblnk  <= delay_vga_in.hblnk ;
        vga_out.rgb    <= rgb_nxt ;
    end
end

always_comb begin
    enable_addres = {enable_start, enable_song_choose, enable_song, enable_endscreen};
    case(enable_addres)
        4'b0001: rgb_nxt = rgb_endscreen;
        4'b0010: rgb_nxt = rgb_song;
        4'b0100: rgb_nxt = rgb_choose;
        4'b1000: rgb_nxt = rgb_start;
    endcase
end

endmodule