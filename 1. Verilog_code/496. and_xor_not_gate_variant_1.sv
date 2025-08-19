//SystemVerilog
// SystemVerilog - IEEE 1364-2005
// 顶层模块 - 连接各个功能子模块
module and_xor_not_gate (
    input  wire clk,      // 时钟输入
    input  wire rst_n,    // 异步复位，低有效
    input  wire A, B, C,  // 数据输入A, B, C
    output wire Y         // 处理后的输出Y
);
    // 内部连线 - 子模块间的连接信号
    wire and_result;      // 第一级计算单元输出 - A与B的与操作结果
    wire not_c_result;    // 第一级计算单元输出 - C的非操作结果
    wire stage1_and;      // 第一级流水线寄存器输出 - 与操作结果
    wire stage1_not_c;    // 第一级流水线寄存器输出 - 非操作结果
    wire xor_result;      // 第二级计算单元输出 - 异或操作结果
    
    // 第一级组合逻辑计算单元
    logic_unit_level1 u_logic_level1 (
        .A(A),
        .B(B),
        .C(C),
        .and_result(and_result),
        .not_c_result(not_c_result)
    );
    
    // 第一级流水线寄存器单元
    pipeline_register_level1 u_pipe_reg_level1 (
        .clk(clk),
        .rst_n(rst_n),
        .and_in(and_result),
        .not_c_in(not_c_result),
        .and_out(stage1_and),
        .not_c_out(stage1_not_c)
    );
    
    // 第二级组合逻辑计算单元
    logic_unit_level2 u_logic_level2 (
        .and_in(stage1_and),
        .not_c_in(stage1_not_c),
        .xor_result(xor_result)
    );
    
    // 第二级流水线寄存器单元
    pipeline_register_level2 u_pipe_reg_level2 (
        .clk(clk),
        .rst_n(rst_n),
        .xor_in(xor_result),
        .result_out(Y)
    );
    
endmodule

// 第一级组合逻辑单元 - 实现AND和NOT操作
module logic_unit_level1 (
    input  wire A, B, C,       // 原始输入数据
    output wire and_result,    // A和B的与操作结果
    output wire not_c_result   // C的非操作结果
);
    // 实现基本逻辑运算
    assign and_result = A & B;    // 数据通路1: AND操作
    assign not_c_result = ~C;     // 数据通路2: NOT操作
endmodule

// 第一级流水线寄存器单元 - 存储第一级运算结果
module pipeline_register_level1 (
    input  wire clk,           // 时钟输入
    input  wire rst_n,         // 异步复位，低有效
    input  wire and_in,        // AND运算结果输入
    input  wire not_c_in,      // NOT运算结果输入
    output reg  and_out,       // 寄存后的AND结果
    output reg  not_c_out      // 寄存后的NOT结果
);
    // 时序逻辑 - 第一级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_out <= 1'b0;
            not_c_out <= 1'b0;
        end else begin
            and_out <= and_in;
            not_c_out <= not_c_in;
        end
    end
endmodule

// 第二级组合逻辑单元 - 实现XOR操作
module logic_unit_level2 (
    input  wire and_in,        // 第一级流水线输出的AND结果
    input  wire not_c_in,      // 第一级流水线输出的NOT结果
    output wire xor_result     // XOR运算结果
);
    // 实现XOR逻辑运算
    assign xor_result = and_in ^ not_c_in;  // 合并数据通路: XOR操作
endmodule

// 第二级流水线寄存器单元 - 存储最终结果
module pipeline_register_level2 (
    input  wire clk,           // 时钟输入
    input  wire rst_n,         // 异步复位，低有效
    input  wire xor_in,        // XOR运算结果输入
    output reg  result_out     // 最终处理结果输出
);
    // 时序逻辑 - 第二级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_out <= 1'b0;
        end else begin
            result_out <= xor_in;
        end
    end
endmodule