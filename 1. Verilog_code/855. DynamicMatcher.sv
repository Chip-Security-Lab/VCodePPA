module DynamicMatcher #(parameter WIDTH=8) (
    input clk,
    input [WIDTH-1:0] data,
    input load, 
    input [WIDTH-1:0] new_pattern,
    output match
);
reg [WIDTH-1:0] current_pattern;
always @(posedge clk) if (load) current_pattern <= new_pattern;
assign match = (data == current_pattern);
endmodule
