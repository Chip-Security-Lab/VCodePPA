//SystemVerilog
module quad_phase_gen #(
    parameter PHASE_NUM = 4
)(
    input clk,
    input rst_n,
    output reg [PHASE_NUM-1:0] phase_clks
);
    // 使用两级寄存器来减少关键路径延迟
    // 使用独立的复位逻辑为每个相位位
    
    // 新增信号用于二进制补码减法
    reg [PHASE_NUM-1:0] phase_clks_next;
    reg [PHASE_NUM-1:0] phase_clks_neg;
    reg [PHASE_NUM-1:0] phase_clks_shifted;
    
    // 计算移位后的相位时钟
    always @(*) begin
        phase_clks_shifted = {phase_clks[PHASE_NUM-2:0], phase_clks[PHASE_NUM-1]};
    end
    
    // 计算相位时钟的二进制补码
    always @(*) begin
        phase_clks_neg = ~phase_clks + 1'b1;
    end
    
    // 使用二进制补码减法计算下一个相位时钟
    always @(*) begin
        phase_clks_next = phase_clks_shifted - phase_clks_neg;
    end
    
    // 主时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_clks <= {{(PHASE_NUM-1){1'b0}}, 1'b1}; // 初始状态：只有最低位为1
        end else begin
            // 使用二进制补码减法实现循环移位
            phase_clks <= phase_clks_next;
        end
    end
endmodule