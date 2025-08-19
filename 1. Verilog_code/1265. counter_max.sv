module counter_max #(parameter MAX=15) (
    input clk, rst,
    output reg [$clog2(MAX):0] cnt
);
always @(posedge clk) begin
    if (rst) cnt <= 0;
    else cnt <= (cnt == MAX) ? MAX : cnt + 1;
end
endmodule