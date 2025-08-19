module EdgeMatcher #(parameter WIDTH=8) (
    input clk,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] pattern,
    output reg edge_match
);
reg last_match;
always @(posedge clk) begin
    last_match <= (data_in == pattern);
    edge_match <= (data_in == pattern) && !last_match;
end
endmodule
