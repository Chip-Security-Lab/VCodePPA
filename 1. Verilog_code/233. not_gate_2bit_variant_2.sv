//SystemVerilog
// 顶层模块 - 重构后的2位非门
module not_gate_2bit (
    input wire [1:0] A,
    input wire clk,       // 添加时钟信号
    input wire rst_n,     // 添加复位信号
    output reg [1:0] Y    // 改为寄存器输出
);
    // 中间信号定义
    wire [1:0] Y_comb;
    
    // 组合逻辑部分 - 使用generate生成多个实例
    genvar i;
    generate
        for (i = 0; i < 2; i = i + 1) begin : NOT_GATES
            // 数据路径第一阶段 - 组合逻辑计算
            not_gate_1bit not_inst (
                .A(A[i]),
                .Y(Y_comb[i])
            );
        end
    endgenerate
    
    // 数据路径第二阶段 - 寄存器采样
    // 添加寄存器层，提高时序性能
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 2'b00;  // 复位值
        end else begin
            Y <= Y_comb; // 寄存输出，切分数据路径
        end
    end

endmodule

// 优化的1位非门子模块
module not_gate_1bit (
    input wire A,
    output wire Y
);
    // 简单组合逻辑 - 保持原有功能
    assign Y = ~A;
endmodule