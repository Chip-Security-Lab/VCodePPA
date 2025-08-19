module RevCounterShift #(parameter N=4) (
    input clk, up_down, load, 
    input [N-1:0] preset,
    output reg [N-1:0] cnt
);
always @(posedge clk) begin
    cnt <= load ? preset : 
          up_down ? {cnt[N-2:0], cnt[N-1]} : // 上移模式
                   {cnt[0], cnt[N-1:1]};    // 下移模式
end
endmodule
