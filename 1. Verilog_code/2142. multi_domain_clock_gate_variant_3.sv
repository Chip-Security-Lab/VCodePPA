//SystemVerilog
module multi_domain_clock_gate (
    input  wire clk_a,
    input  wire clk_b,
    input  wire en_a,
    input  wire en_b,
    output wire gated_clk_a,
    output wire gated_clk_b
);
    // 实例化时钟域A的门控单元
    clock_gate_unit #(
        .INVERT_ENABLE(1'b0)  // 不反转使能信号
    ) u_clock_gate_a (
        .clk_in      (clk_a),
        .enable      (en_a),
        .gated_clk   (gated_clk_a)
    );
    
    // 实例化时钟域B的门控单元 - 使用优化后的反转逻辑
    clock_gate_unit #(
        .INVERT_ENABLE(1'b1)  // 反转使能信号
    ) u_clock_gate_b (
        .clk_in      (clk_b),
        .enable      (en_b),
        .gated_clk   (gated_clk_b)
    );
    
endmodule

// 优化的时钟门控单元，改进了锁存器实现和门控逻辑
module clock_gate_unit #(
    parameter INVERT_ENABLE = 1'b0  // 控制是否需要反转使能信号
)(
    input  wire clk_in,      // 输入时钟
    input  wire enable,      // 使能信号
    output wire gated_clk    // 门控后的时钟
);
    // 直接通过条件操作符应用反转参数，减少一个赋值步骤
    wire effective_enable = INVERT_ENABLE ? ~enable : enable;
    reg  latched_enable;
    
    // 优化的锁存器实现，使用敏感列表明确指定时钟下降沿
    always @(negedge clk_in) begin
        latched_enable <= effective_enable;
    end
    
    // 使用位与操作符实现时钟门控，提高代码可读性
    assign gated_clk = clk_in & latched_enable;
    
endmodule