module PositionMatcher #(parameter WIDTH=8) (
    input clk,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output reg [WIDTH-1:0] match_pos
);
integer i;
always @(posedge clk) begin
    for (i=0; i<WIDTH; i=i+1)
        match_pos[i] <= (data[i] == pattern[i]);
end
endmodule