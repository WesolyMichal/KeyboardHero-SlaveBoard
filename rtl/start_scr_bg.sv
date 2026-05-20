module start_scr_bg (
    input logic clk,
    input logic rst_n,

    vga_if.in vga_in,
    vga_if.out vga_out,

    input logic button
);

logic [11:0] rgb_nxt, d1_rgb;

logic[11:0] diff_x, diff_y;

logic [11:0] pixel_addr;
logic [11:0] pixel_addr_nxt;
logic inside_rect;


delay  #(
        .WIDTH(38), // bit width of the input/output data
        .CLK_DEL(2) // number of clock cycles the data is delayed
    )u_vga_in_del1(
        .clk,
        .rst_n,
        .din({vga_in.vcount, vga_in.hcount, vga_in.vsync, vga_in.hsync, vga_in.vblnk, vga_in.hblnk, vga_in.rgb, in_box_nxt}),
                //37-27 vcount, 26-16 hcount, 15 vsync, 14 hsync, 13 vblnk, 12 hblnk, 11-0 rgb
        .dout({d2_vcount, d2_hcount, d2_vsync, d2_hsync, d2_vblnk, d2_hblnk, d2_rgb})
    );
//logo agh
agh_image_rom u_agh_image_rom (
    .clk,
    .address(pixel_addr),
    .rgb(rgb_pixel)
);
//enter
enter_button_rom u_enter_button_rom  (
    .clk,
    .rom_addr(),
    .enter_pixel_bit()
);




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
        vga_out.vcount  <=  d2_vcount;
        vga_out.hcount  <=  d2_hcount;
        vga_out.vsync   <=  d2_vsync;
        vga_out.hsync   <=  d2_hsync; 
        vga_out.vblnk   <=  d2_vblnk;
        vga_out.hblnk   <=  d2_hblnk;

        vga_out.rgb <= rgb_nxt;
    end
end

always_comb begin
    if(vga_in.hblnk || vga_in.vblnk) begin
        rgb_nxt = 12'h0_0_0;
    end else if((vga_in.hcount >= 448 && vga_in.vcount >= 448) && (vga_in.hcount <= 576 && vga_in.vcount <= 512))begin
        rgb_nxt = rgb_pixel;
    end
end


endmodule