module Demux_Feedback #(parameter DW=8) (
    input clk, 
    input [DW-1:0] data_in,
    input [1:0] sel,
    input [3:0] busy,
    output reg [3:0][DW-1:0] data_out
);
always @(posedge clk) begin
    data_out <= 0;
    if(!busy[sel]) 
        data_out[sel] <= data_in;
end
endmodule
