module ProgIntervalTimer (
    input clk, rst_n, load,
    input [15:0] threshold,
    output reg intr
);
reg [15:0] cnt;
always @(posedge clk) begin
    if (!rst_n) {cnt, intr} <= 0;
    else if (load) cnt <= threshold;
    else begin
        cnt <= (cnt == 0) ? 0 : cnt - 1;
        intr <= (cnt == 16'd1);
    end
end
endmodule
