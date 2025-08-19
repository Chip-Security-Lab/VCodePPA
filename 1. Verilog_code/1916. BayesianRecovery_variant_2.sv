//SystemVerilog
module BayesianRecovery #(parameter WIDTH=8, HIST_DEPTH=4) (
    input clk,
    input [WIDTH-1:0] noisy_in,
    output [WIDTH-1:0] restored
);
    reg [WIDTH-1:0] history [0:HIST_DEPTH-1];
    reg [WIDTH+2:0] prob_sum_reg;
    reg [WIDTH+2:0] prob_sum_next;
    reg [WIDTH-1:0] restored_reg;
    integer i;

    // 历史数据移位
    always @(posedge clk) begin
        for (i = HIST_DEPTH-1; i > 0; i = i - 1) begin
            history[i] <= history[i-1];
        end
        history[0] <= noisy_in;
    end

    // 概率和组合逻辑
    always @(*) begin
        prob_sum_next = history[0] + history[1] + history[2] + history[3];
    end

    // 概率和寄存器
    always @(posedge clk) begin
        prob_sum_reg <= prob_sum_next;
    end

    // 恢复输出逻辑寄存器
    always @(posedge clk) begin
        if (prob_sum_reg > (1 << (WIDTH+1)))
            restored_reg <= {WIDTH{1'b1}};
        else
            restored_reg <= {WIDTH{1'b0}};
    end

    assign restored = restored_reg;
endmodule