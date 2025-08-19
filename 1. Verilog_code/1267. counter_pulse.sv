module counter_pulse #(parameter CYCLE=10) (
    input clk, rst,
    output reg pulse
);
reg [$clog2(CYCLE)-1:0] cnt;
always @(posedge clk) begin
    if (rst) begin
        cnt <= 0;
        pulse <= 0;
    end else begin
        pulse <= (cnt == CYCLE-1);
        cnt <= (cnt == CYCLE-1) ? 0 : cnt + 1;
    end
end
endmodule