module TimerAsyncCmp #(parameter CMP_VAL=8'hFF) (
    input clk, rst_n,
    output wire timer_trigger
);
reg [7:0] cnt;
always @(posedge clk or negedge rst_n)
    if (!rst_n) cnt <= 0;
    else cnt <= cnt + 1;
assign timer_trigger = (cnt == CMP_VAL);
endmodule
