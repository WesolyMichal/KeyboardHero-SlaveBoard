import game_pkg::*;

module song_rom(
    input logic clk,
    input logic [1:0] song_select,

    input logic [7:0] note_addr,
    output note_t note
);

logic [47:0] song_0 [0:127];
logic [47:0] song_1 [0:127];
logic [47:0] song_2 [0:127];
logic [47:0] song_3 [0:127];

initial begin
    $readmemh("../../rtl/core/songs/song_0.data", song_0);
    $readmemh("../../rtl/core/songs/song_1.data", song_1);
    $readmemh("../../rtl/core/songs/song_2.data", song_2);
    $readmemh("../../rtl/core/songs/song_3.data", song_3);
end

always_ff @(posedge clk) begin
    case(song_select)
        2'd0: note <= song_0[note_addr];
        2'd1: note <= song_1[note_addr];
        2'd2: note <= song_2[note_addr];
        2'd3: note <= song_3[note_addr];
    endcase
end

// logic [47:0] songs[0:3][0:127];

// initial begin
//     $readmemh("../../rtl/songs/song_0.data", songs[0]);
//     $readmemh("../../rtl/songs/song_1.data", songs[1]);
//     $readmemh("../../rtl/songs/song_2.data", songs[2]);
//     $readmemh("../../rtl/songs/song_3.data", songs[3]);
// end

// always_ff @(posedge clk)
//     note <= songs[song_select][note_addr];

endmodule