package bg_pkg;
//common
    localparam BASE_CHAR_WIDTH = 8;
    localparam BASE_CHAR_HEIGHT = 16;

    function automatic logic [10:0] wrap_coordinate(
        input logic [10:0] coordinate,
        input logic [10:0] dimension
    );
        wrap_coordinate = (coordinate >= dimension) ? coordinate - dimension : coordinate;
    endfunction
//start_bg
    localparam [11:0] GAME_NAME_COLOR = 12'hf_f_0;
    localparam [11:0] AUTHORS_COLOR = 12'hf_f_f;

    localparam LOGO_X = 11'd0;
    localparam LOGO_Y = 704;
    localparam LOGO_LENGTH = 48; 
    localparam LOGO_WIDTH  = 64; 
    localparam LOGO_SCALE = 1; 
    localparam LOGO_ADDR_SHIFT = $clog2(LOGO_SCALE);

    localparam ENTER_X = 384;
    localparam ENTER_Y = 426;
    localparam ENTER_LENGTH = 128; 
    localparam ENTER_WIDTH  = 64;  
    localparam ENTER_SCALE = 2; 
    localparam ENTER_ADDR_SHIFT = $clog2(ENTER_SCALE);

    localparam GAME_NAME_X = 96;
    localparam GAME_NAME_Y = 200;
    localparam GAME_NAME_LENGTH = 13;
    localparam GAME_NAME_SCALE = 8;
    localparam GAME_NAME_ADDR_SHIFT = $clog2(GAME_NAME_SCALE);
    localparam logic [0:GAME_NAME_LENGTH-1] [7:0] GAME_NAME = "Keyboard-Hero";

    localparam AUTHORS_X = 308; 
    localparam AUTHORS_Y = 720;
    localparam AUTHORS_LENGTH = 51;
    localparam AUTHORS_SCALE = 1;
    localparam AUTHORS_ADDR_SHIFT = $clog2(AUTHORS_SCALE);
    localparam logic [0:AUTHORS_LENGTH-1] [7:0] Authors = "GAME DEVELOPED BY MICHAL WESOLOWSKI AND JAKUB SUDER";


//song_choose_bg
    localparam [11:0] TEXT_COLOR   = 12'hf_f_f;
    localparam [11:0] INSTR_TEXT_COLOR = 12'hf0f;
    localparam [11:0] CURSOR_COLOR = 12'hf_f_0; 

    localparam SCHOOSE_TEXT_SCALE = 2;
    localparam SCHOOSE_TEXT_ADDR_SHIFT = $clog2(SCHOOSE_TEXT_SCALE);
    localparam CHAR_WIDTH = BASE_CHAR_WIDTH * SCHOOSE_TEXT_SCALE;
    localparam CHAR_HEIGHT = BASE_CHAR_HEIGHT * SCHOOSE_TEXT_SCALE;

    localparam HEADING_NAME_START_X = 144;
    localparam HEADING_NAME_START_Y = 33; 
    localparam logic [0:45] [7:0] Heading = "CHOOSE YOUR SONG FROM THE LIST BELOW USING < >";

    localparam SONG_NAME_START_X = 275;
    localparam SONG_NAME_START_Y = 100; 
    localparam CURSOR_X = 250;
    localparam SONG_LEN = 24;
    localparam BASE_ROW_STEP_PIXELS = 32;
    localparam ROW_HEIGHT = CHAR_HEIGHT;
    localparam ROW_STEP_PIXELS = BASE_ROW_STEP_PIXELS * SCHOOSE_TEXT_SCALE;
    localparam ROW_STEP_SHIFT = $clog2(ROW_STEP_PIXELS);
    localparam ROW_INDEX_WIDTH = $clog2(768 / ROW_STEP_PIXELS + 1);
    localparam logic [0:SONG_LEN-1] [7:0] SONG_0 = "1. Wlazl kotek na plotek";
    localparam logic [0:SONG_LEN-1] [7:0] SONG_1 = "2. Hejnal mariacki      ";
    localparam logic [0:SONG_LEN-1] [7:0] SONG_2 = "3. Stairway to Heaven   ";
    localparam logic [0:SONG_LEN-1] [7:0] SONG_3 = "4. Literka A, literka B ";
    
    localparam INSTR_START_X = 32;
    localparam INSTR_START_Y = 420; //;)
    localparam CHAR_IN_LINE = 60;
    localparam INSTR_ROW_STEP_PIXELS = 40;
    localparam INSTR_ROW_INDEX_WIDTH = $clog2(768 / INSTR_ROW_STEP_PIXELS + 1);
    localparam logic [0:CHAR_IN_LINE-1] [7:0] INSTR_0 = "                 HOW TO PLAY KEYBOARD HERO??                ";
    localparam logic [0:CHAR_IN_LINE-1] [7:0] INSTR_1 = "      To play, press SPACEBAR together with buttons 1-6.    ";
    localparam logic [0:CHAR_IN_LINE-1] [7:0] INSTR_2 = "   Buttons 1-6 match the colors of the notes, and SPACEBAR  ";
    localparam logic [0:CHAR_IN_LINE-1] [7:0] INSTR_3 = " acts as STRUM. Use STRUM and NOTE together to HIT the note.";
    localparam logic [0:CHAR_IN_LINE-1] [7:0] INSTR_4 = "          Hold the matching BUTTON for long notes.          ";
    localparam logic [0:CHAR_IN_LINE-1] [7:0] INSTR_5 = "   To NAVIGATE through stages of game press ESC to return   ";
    localparam logic [0:CHAR_IN_LINE-1] [7:0] INSTR_6 = "    or ENTER to go forward or confirm the choice of song.   ";

//song_bg
    localparam [11:0] BG_COLOR   = 12'hfff;
    localparam [11:0] NECK_COLOR = 12'h1_1_2; 
    localparam [11:0] LINE_COLOR = 12'h8_8_9; 

    localparam [11:0] MIBOMBO_OUTLINE = 12'hf_f_f; 

    localparam NECK_X      = 320; 
    localparam NECK_Y      = 0;
    localparam NECK_WIDTH  = 384; 
    localparam NECK_HEIGHT = 768;

    localparam MIBOMBO_WIDTH  = 210;
    localparam MIBOMBO_HEIGHT = 281;
    localparam MIBOMBO_Y      = 400; 

    localparam MIBOMBO_L_X    = 55;  
    localparam MIBOMBO_R_X    = 759; 

    localparam CROWD1_X = 64;
    localparam CROWD1_Y = 188;
    localparam CROWD1_WIDTH = 256;
    localparam CROWD1_HEIGHT = 212;
    localparam CROWD1_SCALE = 2;
    localparam CROWD1_ADDR_SHIFT = $clog2(CROWD1_SCALE);

    localparam CROWD2_X = 704;
    localparam CROWD2_Y = 165;
    localparam CROWD2_WIDTH = 256;
    localparam CROWD2_HEIGHT = 235;
    localparam CROWD2_SCALE = 2;
    localparam CROWD2_ADDR_SHIFT = $clog2(CROWD2_SCALE);

//endscren_bg
    localparam ENDSCREEN_CHAR_SCALE = 8; 
    localparam ENDSCREEN_CHAR_ADDR_SHIFT = $clog2(ENDSCREEN_CHAR_SCALE);

    localparam SCORE_LABEL_X = 160;
    localparam SCORE_LABEL_Y = 200;
    localparam SCORE_LABEL_LENGTH = 11; 
    localparam SCORE_LABEL_WIDTH  = SCORE_LABEL_LENGTH * 8;
    localparam SCORE_LABEL_HEIGHT = 16;
    localparam logic [0:SCORE_LABEL_LENGTH-1] [7:0] SCORE_LABEL = "Your score:";

    localparam SCORE_X = 256;
    localparam SCORE_Y = 340; 
    localparam SCORE_LENGTH = 8; 
    localparam SCORE_WIDTH  = SCORE_LENGTH * 8;

    localparam STAR_X = 238;
    localparam STAR_Y = 468;
    localparam STAR_LENGTH = 50;
    localparam STAR_GAP = 6;
    localparam STAR_NR = 5;
    localparam TILE_WIDTH = STAR_LENGTH + STAR_GAP;
    localparam STARS_LENGTH = (TILE_WIDTH * STAR_NR) - STAR_GAP;
    localparam STAR_SCALE = 2; 
    localparam STAR_ADDR_SHIFT = $clog2(STAR_SCALE);

endpackage