module SyncMatcher #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] data_in, pattern,
    output reg match
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) match <= 1'b0;
    else if (en) match <= (data_in == pattern);
end
endmodule
