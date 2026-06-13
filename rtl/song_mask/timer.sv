module timer #(
    parameter FREQUENCY = 1000
)(
    input logic clk,
    input logic rst_n,
    input logic enable,

    output logic [31:0] count,
    output logic tick,
    output logic enable_out
);

localparam CLK_FREQUENCY = 40_000_000;

logic [31:0] count_nxt;
logic tick_nxt;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        count       <= '0;
        tick        <= '0;
        enable_out  <= '0;
    end else begin
        count <= count_nxt;
        tick <= tick_nxt;
        enable_out <= enable;
    end
end

always_comb begin
    if(enable) begin
        if(count == '0) begin
            tick_nxt = '1;
            count_nxt = CLK_FREQUENCY/FREQUENCY;
        end else begin
            tick_nxt = '0;
            count_nxt = count - 1;
        end
    end else begin
        tick_nxt = '0;
        count_nxt = CLK_FREQUENCY/FREQUENCY;
    end
end

endmodule