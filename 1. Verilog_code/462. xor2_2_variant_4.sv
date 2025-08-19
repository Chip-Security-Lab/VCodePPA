//SystemVerilog
// 顶层模块 - 优化的XOR2实现
module xor2_2 (
    input wire clk,     // 添加时钟信号以支持流水线
    input wire rst_n,   // 添加复位信号
    input wire A, B,    // 输入信号
    output wire Y       // 输出结果
);
    // 数据流路径信号声明
    wire stage1_a, stage1_b;         // 输入寄存器阶段
    wire stage1_eq_result;           // 比较器结果
    wire stage2_eq_signal;           // 流水线寄存器
    wire xor_out;                    // XOR逻辑输出
    
    // 输入寄存器 - 减少输入路径延迟
    input_register input_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .a_in(A),
        .b_in(B),
        .a_out(stage1_a),
        .b_out(stage1_b)
    );
    
    // 比较器阶段 - 优化组合逻辑路径
    equality_comparator comp_inst (
        .in_a(stage1_a),
        .in_b(stage1_b),
        .eq_result(stage1_eq_result)
    );
    
    // 流水线寄存器 - 分割数据路径
    pipeline_register pipe_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .eq_in(stage1_eq_result),
        .eq_out(stage2_eq_signal)
    );
    
    // 输出逻辑阶段 - 优化输出路径
    xor_output_logic out_inst (
        .equal(stage2_eq_signal),
        .xor_result(xor_out)
    );
    
    // 输出寄存器 - 提高输出稳定性
    output_register out_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .xor_in(xor_out),
        .xor_out(Y)
    );
    
endmodule

// 输入寄存器模块
module input_register (
    input wire clk,
    input wire rst_n,
    input wire a_in, b_in,
    output reg a_out, b_out
);
    // 寄存输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out <= 1'b0;
            b_out <= 1'b0;
        end else begin
            a_out <= a_in;
            b_out <= b_in;
        end
    end
endmodule

// 优化的比较器子模块
module equality_comparator (
    input wire in_a, in_b,
    output reg eq_result
);
    // 比较两个输入是否相等 - 拆分复杂组合路径
    always @(*) begin
        eq_result = (in_a == in_b);
    end
endmodule

// 流水线寄存器模块
module pipeline_register (
    input wire clk,
    input wire rst_n,
    input wire eq_in,
    output reg eq_out
);
    // 寄存中间结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            eq_out <= 1'b0;
        end else begin
            eq_out <= eq_in;
        end
    end
endmodule

// 优化的输出逻辑子模块
module xor_output_logic (
    input wire equal,
    output wire xor_result
);
    // 根据相等信号生成XOR结果
    assign xor_result = ~equal;
endmodule

// 输出寄存器模块
module output_register (
    input wire clk,
    input wire rst_n,
    input wire xor_in,
    output reg xor_out
);
    // 寄存输出结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_out <= 1'b0;
        end else begin
            xor_out <= xor_in;
        end
    end
endmodule