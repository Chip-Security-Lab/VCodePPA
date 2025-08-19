//SystemVerilog
module BayesianRecovery #(parameter WIDTH=8, HIST_DEPTH=4) (
    input clk,
    input [WIDTH-1:0] noisy_in,
    output reg [WIDTH-1:0] restored
);
    reg [WIDTH-1:0] history [0:HIST_DEPTH-1];
    wire [WIDTH+2:0] prob_sum;  // 更宽以容纳和
    reg [WIDTH+2:0] prob_sum_reg;
    integer i;

    // 历史寄存器移到组合逻辑后
    always @(*) begin
        history[0] = noisy_in;
        for (i = 1; i < HIST_DEPTH; i = i + 1) begin
            history[i] = history[i-1];
        end
    end

    // 概率和组合逻辑
    assign prob_sum = history[0] + history[1] + history[2] + history[3];

    // 概率和寄存器
    always @(posedge clk) begin
        prob_sum_reg <= prob_sum;
    end

    // 输出寄存器
    always @(posedge clk) begin
        restored <= (prob_sum_reg > (1 << (WIDTH+1))) ? {WIDTH{1'b1}} : {WIDTH{1'b0}};
    end
endmodule