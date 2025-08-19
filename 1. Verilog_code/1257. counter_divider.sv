module counter_divider #(parameter RATIO=10) (
    input clk, rst,
    output reg clk_out
);
reg [$clog2(RATIO)-1:0] cnt;
always @(posedge clk) begin
    if (rst) begin
        cnt <= 0;
        clk_out <= 0;
    end else if (cnt == RATIO-1) begin
        cnt <= 0;
        clk_out <= ~clk_out;
    end else cnt <= cnt + 1;
end
endmodule