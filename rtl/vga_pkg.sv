package vga_pkg;

    typedef struct packed {
        logic [10:0] vcount;
        logic [10:0] hcount;
        logic vsync;
        logic hsync;
        logic vblnk;
        logic hblnk;
        logic [11:0] rgb;
    } vga_if;

    // Parameters for VGA Display 1024 x 768 @ 60fps using a 65 MHz clock;
    localparam HOR_PIXELS = 1024;
    localparam VER_PIXELS = 768;
   
    localparam HOR_FRONT_PORCH  = 24;
    localparam HOR_SYNC_TIME    = 136;
    localparam HOR_BACK_PORCH   = 160;
    localparam HOR_BLANK_START = 1024;
    localparam HOR_BLANK_TIME = 320;

    localparam HOR_SYNC_START   = HOR_PIXELS + HOR_FRONT_PORCH; //1048;
    localparam HOR_SYNC_END     = HOR_SYNC_START + HOR_SYNC_TIME;//1184
    localparam HOR_TOTAL_TIME = HOR_PIXELS + HOR_FRONT_PORCH + HOR_SYNC_TIME + HOR_BACK_PORCH;//1344
    
    localparam VER_FRONT_PORCH  = 3;
    localparam VER_SYNC_TIME    = 6;
    localparam VER_BACK_PORCH   = 29;
    localparam VER_BLANK_START = 768;
    localparam VER_BLANK_TIME = 38;

    localparam VER_SYNC_START   = VER_PIXELS + VER_FRONT_PORCH;//771
    localparam VER_SYNC_END     = VER_SYNC_START + VER_SYNC_TIME;//777
    localparam VER_TOTAL_TIME   = VER_PIXELS + VER_FRONT_PORCH + VER_SYNC_TIME + VER_BACK_PORCH;//806

endpackage
