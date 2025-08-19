module Timer_AsyncComb (
    input clk, rst,
    input [4:0] delay,
    output timeout
);
    reg [4:0] cnt;
    always @(posedge clk or posedge rst) begin
        if (rst) cnt <= 0;
        else cnt <= cnt + 1;
    end
    assign timeout = (cnt == delay);  // 异步比较
endmodule