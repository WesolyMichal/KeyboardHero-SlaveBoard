import song_mask_pkg::*;

module song_out_logic(
    input logic clk,
    input logic rst_n,
    input logic enable_in,

    input logic note_fill[0:5][0:639],
    vga_if.in vga_in,
    vga_if.out vga_out
);

logic [11:0] rgb_nxt;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        vga_out.vcount <= '0;
        vga_out.vsync  <= '0;
        vga_out.vblnk  <= '0;
        vga_out.hcount <= '0;
        vga_out.hsync  <= '0;
        vga_out.hblnk  <= '0;
        vga_out.rgb    <= '0;
    end else begin
        vga_out.vcount <= vga_in.vcount;
        vga_out.vsync  <= vga_in.vsync ;
        vga_out.vblnk  <= vga_in.vblnk ;
        vga_out.hcount <= vga_in.hcount ;
        vga_out.hsync  <= vga_in.hsync ;
        vga_out.hblnk  <= vga_in.hblnk ;
        vga_out.rgb    <= rgb_nxt;
    end
end

always_comb begin
    rgb_nxt = vga_in.rgb;

    if(enable_in) begin

        if(vga_in.vcount < NOTE_DISPLAY_HEIGHT) begin

            for(logic [2:0] column = 0; column < 6; column++) begin

                if((vga_in.hcount >= COLUMN_XPOS[column]) 
                && (vga_in.hcount <  COLUMN_XPOS[column] + COLUMN_WIDTH)) begin
                    
                    if(note_fill[column][(NOTE_DISPLAY_HEIGHT - 1) - vga_in.vcount])
                        rgb_nxt = COLUMN_COLOURS[column];

                end    

            end

        end

    end
end

endmodule