module RangeDetector_MultiMode #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [1:0] mode,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg flag
);
always @(posedge clk) begin
    case(mode)
        2'b00: flag <= (data_in >= threshold);
        2'b01: flag <= (data_in <= threshold);
        2'b10: flag <= (data_in != threshold);
        2'b11: flag <= (data_in == threshold);
    endcase
end
endmodule