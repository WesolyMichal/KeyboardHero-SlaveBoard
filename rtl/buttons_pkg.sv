package buttons_pkg;
        localparam logic [7:0] BTN_ESC   = 8'h76; // ESC
        localparam logic [7:0] BTN_ENTER = 8'h5A; // ENTER

        // --- Klawisze numeryczne (górny rząd na klawiaturze) ---
        localparam logic [7:0] BTN_1 = 8'h16;
        localparam logic [7:0] BTN_2 = 8'h1E;
        localparam logic [7:0] BTN_3 = 8'h26;
        localparam logic [7:0] BTN_4 = 8'h25;
        localparam logic [7:0] BTN_5 = 8'h2E;
        localparam logic [7:0] BTN_6 = 8'h36;

        // --- Znaki mniejszości / większości ---
        // Na klawiaturze znak '<' to fizycznie klawisz przecinka (,), a '>' to klawisz kropki (.)
        localparam logic [7:0] BTN_UP    = 8'h41; // Klawisz: , <
        localparam logic [7:0] BTN_DOWN = 8'h49; // Klawisz: . >

endpackage