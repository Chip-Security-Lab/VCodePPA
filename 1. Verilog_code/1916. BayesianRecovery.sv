module BayesianRecovery #(parameter WIDTH=8, HIST_DEPTH=4) (
    input clk,
    input [WIDTH-1:0] noisy_in,
    output reg [WIDTH-1:0] restored
);
    reg [WIDTH-1:0] history [0:HIST_DEPTH-1];
    wire [WIDTH+2:0] prob_sum;  // 更宽以容纳和
    integer i;

    always @(posedge clk) begin
        // 修复错误的数组赋值
        for (i = HIST_DEPTH-1; i > 0; i = i - 1) begin
            history[i] <= history[i-1];
        end
        history[0] <= noisy_in;
    end
    
    // 计算概率和
    assign prob_sum = history[0] + history[1] + history[2] + history[3];
    
    always @(posedge clk) begin
        restored <= (prob_sum > (1 << (WIDTH+1))) ? {WIDTH{1'b1}} : {WIDTH{1'b0}};
    end
endmodule