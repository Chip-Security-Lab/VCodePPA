module digital_differentiator #(parameter WIDTH=8) (
    input clk, rst,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_diff
);
reg [WIDTH-1:0] prev_data;

always @(posedge clk or posedge rst) 
    if (rst) prev_data <= 0;
    else prev_data <= data_in;

assign data_diff = data_in ^ prev_data;
endmodule