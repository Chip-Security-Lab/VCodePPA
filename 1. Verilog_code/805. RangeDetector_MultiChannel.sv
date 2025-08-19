module RangeDetector_MultiChannel #(
    parameter WIDTH = 8,
    parameter CHANNELS = 4
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] thresholds [CHANNELS*2-1:0],
    input [$clog2(CHANNELS)-1:0] ch_sel,
    output reg out_flag
);
always @(posedge clk) begin
    out_flag <= (data_in >= thresholds[ch_sel*2]) && 
               (data_in <= thresholds[ch_sel*2+1]);
end
endmodule