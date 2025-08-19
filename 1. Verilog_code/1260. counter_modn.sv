module counter_modn #(parameter N=10) (
    input clk, rst,
    output reg [$clog2(N)-1:0] cnt
);
always @(posedge clk) begin
    if (rst) cnt <= 0;
    else cnt <= (cnt == N-1) ? 0 : cnt + 1;
end
endmodule