//SystemVerilog
// 顶层模块
module xor_multi_driver (
    input  wire        clk,      // 增加时钟输入用于流水线
    input  wire        rst_n,    // 增加复位信号
    input  wire        a,
    input  wire        b,
    output wire        y
);
    // 内部信号声明
    wire        xor_result;      // 单一XOR结果
    
    // 流水线寄存器
    reg         a_reg, b_reg;    // 输入寄存器
    reg         xor_stage1;      // 第一级流水线
    reg         xor_stage2;      // 第二级流水线
    
    // 输入寄存器级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 1'b0;
            b_reg <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // XOR操作
    xor_operation xor_inst (
        .in_a    (a_reg),
        .in_b    (b_reg),
        .xor_out (xor_result)
    );
    
    // 第一级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_stage1 <= 1'b0;
        end else begin
            xor_stage1 <= xor_result;
        end
    end
    
    // 第二级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_stage2 <= 1'b0;
        end else begin
            xor_stage2 <= xor_stage1;
        end
    end
    
    // 输出驱动
    output_driver out_driver_inst (
        .driver_in1 (xor_stage1),
        .driver_in2 (xor_stage2),
        .driver_out (y)
    );
    
endmodule

// XOR运算子模块 - 优化为单一操作
module xor_operation (
    input  wire in_a,
    input  wire in_b,
    output wire xor_out
);
    // 添加参数以支持可配置的位宽
    assign xor_out = in_a ^ in_b;
endmodule

// 优化后的输出驱动子模块
module output_driver (
    input  wire driver_in1,
    input  wire driver_in2,
    output wire driver_out
);
    // 保持原有的冗余检查逻辑
    assign driver_out = driver_in1 & driver_in2;
endmodule