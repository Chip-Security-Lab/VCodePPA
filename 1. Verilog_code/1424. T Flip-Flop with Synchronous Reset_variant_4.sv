//SystemVerilog
module t_ff_sync_reset (
    input wire clock,
    input wire reset,
    input wire toggle,
    output reg q_out
);
    // 移除toggle_reg，直接使用输入信号
    reg q_internal;
    wire next_q;
    
    // 组合逻辑计算下一状态，直接使用toggle输入
    assign next_q = toggle ? ~q_internal : q_internal;
    
    // 中间寄存器，替代了原来的输出寄存器
    always @(posedge clock) begin
        if (reset)
            q_internal <= 1'b0;
        else
            q_internal <= next_q;
    end
    
    // 输出寄存器移动到了组合逻辑之后
    always @(posedge clock) begin
        if (reset)
            q_out <= 1'b0;
        else
            q_out <= q_internal;
    end
endmodule