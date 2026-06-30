import vga_pkg::*;

module button_mask(
    input logic clk,
    input logic rst_n,
    
    input logic [5:0] buttons,

    input logic enable_in,
    output logic enable_out,

    input vga_if vga_in,
    output vga_if vga_out
);

endmodule