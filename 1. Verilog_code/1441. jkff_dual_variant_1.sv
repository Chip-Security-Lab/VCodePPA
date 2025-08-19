//SystemVerilog
module jkff_dual (
    input  wire clk, rstn,
    input  wire j, k,
    output wire q
);
    reg q_pos, q_neg;
    wire next_q_pos, next_q_neg;
    
    // 简化的next state逻辑，使用布尔表达式代替case语句
    // 应用布尔代数: next_q = (~k & q) | (j & ~q) | (j & ~k)
    // 进一步简化为: next_q = (~k & q) | (j & ~k) | (j & ~q)
    // 最终优化为: next_q = (j & ~q) | (~k & q)
    assign next_q_pos = (j & ~q_pos) | (~k & q_pos);
    assign next_q_neg = (j & ~q_neg) | (~k & q_neg);

    // 时序逻辑保持不变但直接连接到简化的组合逻辑
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            q_pos <= 1'b0;
        else
            q_pos <= next_q_pos;
    end

    always @(negedge clk or negedge rstn) begin
        if (!rstn)
            q_neg <= 1'b0;
        else
            q_neg <= next_q_neg;
    end

    // 输出选择逻辑
    assign q = clk ? q_pos : q_neg;
endmodule