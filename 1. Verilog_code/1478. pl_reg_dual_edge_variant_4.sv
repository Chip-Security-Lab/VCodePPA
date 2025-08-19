//SystemVerilog
module pl_reg_dual_edge #(parameter W=8) (
    input clk, load, rstn,
    input [W-1:0] d,
    output [W-1:0] q
);
    // 内部信号定义
    reg [W-1:0] q_pos, q_neg;
    reg clk_sample;
    
    // 采样时钟值用于输出选择 - 简化复位逻辑
    always @(posedge clk or negedge rstn) begin
        if (!rstn) 
            clk_sample <= 1'b0;
        else 
            clk_sample <= 1'b1;
    end
    
    // 正边沿触发寄存器 - 移除冗余门控逻辑
    always @(posedge clk or negedge rstn) begin
        if (!rstn) 
            q_pos <= {W{1'b0}};
        else if (load) 
            q_pos <= d;
    end
    
    // 负边沿触发寄存器 - 移除冗余门控逻辑
    always @(negedge clk or negedge rstn) begin
        if (!rstn) 
            q_neg <= {W{1'b0}};
        else if (load) 
            q_neg <= d;
    end
    
    // 优化多路复用器实现
    assign q = clk_sample ? q_pos : q_neg;
endmodule