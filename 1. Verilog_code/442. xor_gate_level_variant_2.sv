//SystemVerilog
// 顶层模块
module xor_gate_level (
    input  wire clk,    // 时钟输入用于流水线寄存器
    input  wire rst_n,  // 复位信号
    input  wire a, 
    input  wire b, 
    output wire y
);
    // 内部信号声明 - 分离组合信号和寄存器信号
    // 第一级流水线信号
    reg  a_stage1_reg, b_stage1_reg;
    wire not_a_stage1, not_b_stage1;
    
    // 第二级流水线信号
    reg  a_stage2_reg, b_stage2_reg;
    reg  not_a_stage2_reg, not_b_stage2_reg;
    wire path1_result, path2_result;
    
    // 第三级流水线信号
    reg  path1_reg, path2_reg;
    
    //===== 时序逻辑部分 =====
    // 第一级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1_reg <= 1'b0;
            b_stage1_reg <= 1'b0;
        end else begin
            a_stage1_reg <= a;
            b_stage1_reg <= b;
        end
    end
    
    // 第二级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage2_reg    <= 1'b0;
            b_stage2_reg    <= 1'b0;
            not_a_stage2_reg <= 1'b0;
            not_b_stage2_reg <= 1'b0;
        end else begin
            a_stage2_reg    <= a_stage1_reg;
            b_stage2_reg    <= b_stage1_reg;
            not_a_stage2_reg <= not_a_stage1;
            not_b_stage2_reg <= not_b_stage1;
        end
    end
    
    // 第三级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            path1_reg <= 1'b0;
            path2_reg <= 1'b0;
        end else begin
            path1_reg <= path1_result;
            path2_reg <= path2_result;
        end
    end
    
    //===== 组合逻辑部分 =====
    // 第一级反相器实例化
    inverter_module inv_a (
        .in(a_stage1_reg),
        .out(not_a_stage1)
    );
    
    inverter_module inv_b (
        .in(b_stage1_reg),
        .out(not_b_stage1)
    );
    
    // 第二级并行数据路径
    and_module and_path1 (
        .in1(a_stage2_reg),
        .in2(not_b_stage2_reg),
        .out(path1_result)
    );
    
    and_module and_path2 (
        .in1(not_a_stage2_reg),
        .in2(b_stage2_reg),
        .out(path2_result)
    );
    
    // 最终输出逻辑
    or_module final_output (
        .in1(path1_reg),
        .in2(path2_reg),
        .out(y)
    );
endmodule

// 优化的组合逻辑子模块
// 非门子模块
module inverter_module (
    input  wire in,
    output wire out
);
    // 纯组合逻辑
    assign out = ~in;
endmodule

// 与门子模块
module and_module (
    input  wire in1,
    input  wire in2,
    output wire out
);
    // 纯组合逻辑
    assign out = in1 & in2;
endmodule

// 或门子模块
module or_module (
    input  wire in1,
    input  wire in2,
    output wire out
);
    // 纯组合逻辑
    assign out = in1 | in2;
endmodule