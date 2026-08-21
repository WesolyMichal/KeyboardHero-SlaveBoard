package song_mask_pkg;
//do uzupełnienia / poprawienia - to sa same placeholdery

    localparam logic [11:0] COLOUR_RED = 12'hf_0_0;
    localparam logic [11:0] COLOUR_GREEN = 12'h0_f_0;
    localparam logic [11:0] COLOUR_BLUE = 12'h0_0_f;
    localparam logic [11:0] COLOUR_YELLOW = 12'hf_f_0;
    localparam logic [11:0] COLOUR_MAGENTA = 12'hf_0_f;
    localparam logic [11:0] COLOUR_CYAN = 12'h0_f_f;

    localparam NOTE_DISPLAY_HEIGHT = 640;

    // First line of each of the six 64-pixel gryf columns.
    localparam [10:0] COLUMN_XPOS[0:5] = {320, 384, 448, 512, 576, 640};

    localparam [11:0] COLUMN_COLOURS [0:5] = {COLOUR_RED,
                                              COLOUR_GREEN,
                                              COLOUR_BLUE,
                                              COLOUR_YELLOW,
                                              COLOUR_MAGENTA,
                                              COLOUR_CYAN};

    localparam COLUMN_WIDTH = 64;
    localparam NOTE_WIDTH = 30;
    localparam NOTE_OFFSET = (COLUMN_WIDTH - NOTE_WIDTH) / 2;

    localparam SCREEN_HEIGHT = 640;

endpackage