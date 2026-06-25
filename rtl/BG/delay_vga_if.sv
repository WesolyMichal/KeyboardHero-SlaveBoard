module delay_vga_if #(
    parameter CLK_DEL = 2
)(
    input logic clk,
    input logic rst_n,
    vga_if vga_in,
    vga_if delay_vga_out
);

logic [10:0] d2_vcount, d2_hcount;
logic        d2_vsync, d2_hsync, d2_vblnk, d2_hblnk;

delay  #(
        .WIDTH(26), 
        .CLK_DEL(CLK_DEL)
    )u_vga_in_del2(
        .clk,
        .rst_n,
        .din({vga_in.vcount, vga_in.hcount, vga_in.vsync, vga_in.hsync, vga_in.vblnk, vga_in.hblnk}),
        .dout({d2_vcount, d2_hcount, d2_vsync, d2_hsync, d2_vblnk, d2_hblnk})
    );

    // Wyjściowy rejestr
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        delay_vga_out.vcount <= '0;
        delay_vga_out.vsync  <= '0;
        delay_vga_out.vblnk  <= '0;
        delay_vga_out.hcount <= '0;
        delay_vga_out.hsync  <= '0;
        delay_vga_out.hblnk  <= '0;

    end else begin
        delay_vga_out.vcount  <= d2_vcount;
        delay_vga_out.hcount  <= d2_hcount;
        delay_vga_out.vsync   <= d2_vsync;
        delay_vga_out.hsync   <= d2_hsync; 
        delay_vga_out.vblnk   <= d2_vblnk;
        delay_vga_out.hblnk   <= d2_hblnk;
    end
end

endmodule