//SystemVerilog
// 顶层模块：4位XOR操作（流水线优化版）
module xor2_12 (
    input wire clk,         // 时钟信号
    input wire rst_n,       // 复位信号
    input wire [3:0] A, B,  // 输入操作数
    output reg [3:0] Y      // 输出结果
);
    // 内部流水线阶段信号
    reg [3:0] stage1_a, stage1_b;    // 第一级流水线寄存器
    wire [3:0] stage1_xor_result;    // 第一级XOR结果
    reg [3:0] stage2_xor_result;     // 第二级流水线寄存器

    // 第一级流水线：寄存输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 4'b0;
            stage1_b <= 4'b0;
        end else begin
            stage1_a <= A;
            stage1_b <= B;
        end
    end

    // XOR运算子模块实例化（组合逻辑核心）
    xor2_12_datapath xor_datapath_inst (
        .a_data(stage1_a),
        .b_data(stage1_b),
        .result(stage1_xor_result)
    );

    // 第二级流水线：寄存中间结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_xor_result <= 4'b0;
        end else begin
            stage2_xor_result <= stage1_xor_result;
        end
    end

    // 输出级：将结果传递到输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 4'b0;
        end else begin
            Y <= stage2_xor_result;
        end
    end
endmodule

// 数据路径模块：处理4位XOR操作
module xor2_12_datapath (
    input wire [3:0] a_data,
    input wire [3:0] b_data,
    output wire [3:0] result
);
    // 并行处理每个位的XOR操作
    xor2_12_bit_operator bit0_xor (
        .a_in(a_data[0]),
        .b_in(b_data[0]),
        .y_out(result[0])
    );
    
    xor2_12_bit_operator bit1_xor (
        .a_in(a_data[1]),
        .b_in(b_data[1]),
        .y_out(result[1])
    );
    
    xor2_12_bit_operator bit2_xor (
        .a_in(a_data[2]),
        .b_in(b_data[2]),
        .y_out(result[2])
    );
    
    xor2_12_bit_operator bit3_xor (
        .a_in(a_data[3]),
        .b_in(b_data[3]),
        .y_out(result[3])
    );
endmodule

// 优化的单比特XOR运算器
module xor2_12_bit_operator (
    input wire a_in,
    input wire b_in,
    output wire y_out
);
    // 声明中间信号
    wire a_nand_b;     // A NAND B
    wire a_or_b;       // A OR B
    
    // 优化的XOR实现（降低逻辑深度）
    // XOR可表示为: (A OR B) AND (NOT(A AND B))
    assign a_nand_b = ~(a_in & b_in);
    assign a_or_b = a_in | b_in;
    assign y_out = a_nand_b & a_or_b;
endmodule