//SystemVerilog
// 顶层模块
module xor_or_gate (
    input  wire clk,      // 时钟输入
    input  wire rst_n,    // 复位信号，低电平有效
    input  wire A, B, C,  // 输入A, B, C
    output wire Y         // 输出Y
);
    // 内部信号定义 - 数据流路径
    wire   stage1_xor_result;  // 第一阶段：XOR结果
    reg    stage2_xor_reg;     // 第二阶段：XOR结果寄存器
    reg    stage2_c_reg;       // 第二阶段：C输入寄存器
    wire   stage3_or_result;   // 第三阶段：OR结果
    reg    stage4_result_reg;  // 第四阶段：最终结果寄存器

    // 第一阶段：执行XOR操作
    xor_module xor_stage (
        .in1(A),
        .in2(B),
        .out(stage1_xor_result)
    );
    
    // 第二阶段：寄存器级，切分数据路径 - 扁平化if-else结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_xor_reg <= 1'b0;
            stage2_c_reg   <= 1'b0;
        end 
        else begin
            stage2_xor_reg <= stage1_xor_result;
            stage2_c_reg   <= C;
        end
    end
    
    // 第三阶段：执行OR操作
    or_module or_stage (
        .in1(stage2_xor_reg),
        .in2(stage2_c_reg),
        .out(stage3_or_result)
    );
    
    // 第四阶段：输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage4_result_reg <= 1'b0;
        end 
        else begin
            stage4_result_reg <= stage3_or_result;
        end
    end
    
    // 输出赋值
    assign Y = stage4_result_reg;
    
endmodule

// 优化的XOR子模块
module xor_module (
    input  wire in1, in2,  // 输入
    output wire out        // 输出
);
    // 使用简化的XOR实现，减少面积和功耗
    assign out = in1 ^ in2;
endmodule

// 优化的OR子模块
module or_module (
    input  wire in1, in2,  // 输入
    output wire out        // 输出
);
    // 直接使用OR操作，降低延迟
    assign out = in1 | in2;
endmodule