package game_pkg;

    typedef struct packed {
        logic [15:0] duration;
        logic [15:0] waiting;
        logic [5:0] buttons;
        logic [5:0] long;
        logic [3:0] data;
    } note_t;

    typedef struct packed {
        logic esc;
        logic enter;
        logic arr_left;
        logic arr_right;
    } navigation;

    typedef enum logic [1:0] {HIT, MISS, PLAYER_IDLE, END_GAME} game_action;

    typedef struct packed {
        logic [5:0] buttons;
        game_action status;
    } game_if;

    //COLOURS
    localparam logic [11:0] COLOUR_RED = 12'hf_0_0;
    localparam logic [11:0] COLOUR_GREEN = 12'h0_f_0;
    localparam logic [11:0] COLOUR_BLUE = 12'h0_0_f;
    localparam logic [11:0] COLOUR_YELLOW = 12'hf_f_0;
    localparam logic [11:0] COLOUR_MAGENTA = 12'hf_0_f;
    localparam logic [11:0] COLOUR_CYAN = 12'h0_f_f;

    //HIT MARGINS
    localparam HIT_MARGIN = 50;

    //for simulation !!!
    //localparam HIT_MARGIN = 5;

    //KEY CODES - all are placeholders
    localparam ESC = 8'h76;
    localparam ENTER = 8'h5A;
    localparam ARR_LEFT = 8'h41;
    localparam ARR_RIGHT = 8'h49;

    localparam BUTTON_1 = 8'h16;
    localparam BUTTON_2 = 8'h1E;
    localparam BUTTON_3 = 8'h26;
    localparam BUTTON_4 = 8'h25;
    localparam BUTTON_5 = 8'h2E;
    localparam BUTTON_6 = 8'h36;
    localparam STRUM    = 8'h29;

    localparam RELEASED = 8'hF0;

    //SONG CHOOSING
    localparam CHOOSE = 4'hf;
    localparam CONFIRM = 4'hA;

    localparam HALT = 8'hff;

    //UART SELECT
    localparam UART_FSM = 1'b0;
    localparam UART_GAME = 1'b1;

endpackage