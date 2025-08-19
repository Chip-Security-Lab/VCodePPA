//SystemVerilog
// 顶层模块
module nand_xor_xnor_gate (
    input wire clk,         // 时钟信号
    input wire rst_n,       // 复位信号（低电平有效）
    input wire A, B, C,     // 输入信号
    output wire Y           // 输出信号
);
    // 内部连线
    wire nand_result;                // NAND运算结果
    wire xnor_result;                // XNOR运算结果
    wire stage2_nand_result;         // 第二级寄存的NAND结果
    wire stage2_xnor_result;         // 第二级寄存的XNOR结果
    wire [1:0] stage3_operands;      // 第三级流水线数据

    // 第一级流水线 - 逻辑计算模块
    logic_calculation_stage stage1 (
        .clk(clk),
        .rst_n(rst_n),
        .A(A),
        .B(B),
        .C(C),
        .nand_result(nand_result),
        .xnor_result(xnor_result)
    );

    // 第二级流水线 - 结果保持模块
    result_pipeline_stage stage2 (
        .clk(clk),
        .rst_n(rst_n),
        .nand_in(nand_result),
        .xnor_in(xnor_result),
        .nand_out(stage2_nand_result),
        .xnor_out(stage2_xnor_result)
    );

    // 第三级流水线 - 操作数准备模块
    operand_preparation_stage stage3 (
        .clk(clk),
        .rst_n(rst_n),
        .nand_in(stage2_nand_result),
        .xnor_in(stage2_xnor_result),
        .operands_out(stage3_operands)
    );

    // 输出级 - 最终XOR运算模块
    output_calculation_stage stage4 (
        .clk(clk),
        .rst_n(rst_n),
        .operands_in(stage3_operands),
        .Y(Y)
    );

endmodule

// 第一级流水线 - 逻辑计算模块
module logic_calculation_stage (
    input wire clk,
    input wire rst_n,
    input wire A, B, C,
    output reg nand_result,
    output reg xnor_result
);
    // 组合逻辑计算后直接寄存结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nand_result <= 1'b1;
            xnor_result <= 1'b0;
        end else begin
            nand_result <= ~(A & B);   // 输入NAND运算
            xnor_result <= ~(C ^ A);   // 输入XNOR运算
        end
    end
endmodule

// 第二级流水线 - 结果保持模块
module result_pipeline_stage (
    input wire clk,
    input wire rst_n,
    input wire nand_in,
    input wire xnor_in,
    output reg nand_out,
    output reg xnor_out
);
    // 保持中间结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nand_out <= 1'b1;
            xnor_out <= 1'b0;
        end else begin
            nand_out <= nand_in;
            xnor_out <= xnor_in;
        end
    end
endmodule

// 第三级流水线 - 操作数准备模块
module operand_preparation_stage (
    input wire clk,
    input wire rst_n,
    input wire nand_in,
    input wire xnor_in,
    output reg [1:0] operands_out
);
    // 准备最终XOR操作的操作数
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            operands_out <= 2'b00;
        end else begin
            operands_out <= {nand_in, xnor_in};
        end
    end
endmodule

// 输出级 - 最终XOR运算模块
module output_calculation_stage (
    input wire clk,
    input wire rst_n,
    input wire [1:0] operands_in,
    output reg Y
);
    // 最终XOR运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= operands_in[1] ^ operands_in[0];  // NAND结果与XNOR结果进行XOR运算
        end
    end
endmodule