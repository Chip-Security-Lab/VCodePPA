module CounterMatcher #(parameter WIDTH=8) (
    input clk, rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output reg [15:0] match_count
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) match_count <= 0;
    else if (data == pattern) match_count <= match_count + 1;
end
endmodule
