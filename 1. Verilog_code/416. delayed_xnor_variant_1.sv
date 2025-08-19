//SystemVerilog
// 顶层模块
module delayed_xnor (
    input  wire         clk,    // 新增时钟信号以支持流水线
    input  wire         rst_n,  // 新增复位信号
    input  wire         a, b,
    output wire         y
);
    // 内部连线 - 增加流水线寄存器
    wire         xor_stage1;
    reg          xor_stage2;
    reg          xor_stage3;
    
    // 第一级：XOR操作
    xor_operation xor_inst (
        .in1        (a),
        .in2        (b),
        .xor_out    (xor_stage1)
    );
    
    // 流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_stage2 <= 1'b0;
            xor_stage3 <= 1'b0;
        end else begin
            xor_stage2 <= xor_stage1;  // 第一个流水线级
            xor_stage3 <= xor_stage2;  // 第二个流水线级
        end
    end
    
    // 输出级：反相操作
    inverter_module inv_inst (
        .inv_in     (xor_stage3),
        .inv_out    (y)
    );
    
endmodule

// 子模块1：优化的XOR操作
module xor_operation (
    input  wire         in1, in2,
    output wire         xor_out
);
    // 执行XOR操作 - 确保明确的数据路径
    assign xor_out = in1 ^ in2;
    
endmodule

// 子模块2：优化的反相器 - 移除延迟，改为组合逻辑
module inverter_module (
    input  wire         inv_in,
    output wire         inv_out
);
    // 反相操作 - 移除不可综合的延迟，转为纯组合逻辑
    assign inv_out = ~inv_in;
    
endmodule