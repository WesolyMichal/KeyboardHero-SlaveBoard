interface vga_if;
    logic [10:0] vcount;
    logic [10:0] hcount;
    logic vsync;
    logic hsync;
    logic vblnk;
    logic hblnk;
    logic [11:0] rgb;

    modport in (
        input vcount, hcount, vsync, hsync, vblnk, hblnk, rgb
    );

    modport out(
        output vcount, hcount, vsync, hsync, vblnk, hblnk, rgb
    );
    
    modport in_bez_rgb(
        input vcount, hcount, vsync, hsync, vblnk, hblnk
    );

    modport out_bez_rgb(
        output vcount, hcount, vsync, hsync, vblnk, hblnk
    );

endinterface