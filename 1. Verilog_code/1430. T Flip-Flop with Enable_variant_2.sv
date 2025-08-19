//SystemVerilog
module t_ff_enable (
    input wire clk,
    input wire en,
    input wire t,
    output wire q
);
    // 输入寄存器
    reg en_reg, t_reg;
    reg valid_reg;
    
    // 计算结果寄存器和中间信号
    reg q_internal;
    wire q_next;
    
    // 计算逻辑提前到寄存器前
    assign q_next = en_reg ? (t_reg ? ~q_internal : q_internal) : q_internal;
    
    // 寄存器控制逻辑
    always @(posedge clk) begin
        // 寄存输入信号
        en_reg <= en;
        t_reg <= t;
        valid_reg <= 1'b1;  // 第一个时钟后始终有效
        
        // 将逻辑结果寄存
        if (valid_reg)
            q_internal <= q_next;
    end
    
    // 输出赋值
    assign q = q_internal;
    
endmodule