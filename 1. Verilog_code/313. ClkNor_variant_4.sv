//SystemVerilog
// SystemVerilog
module ClkNor (
    input  logic clk,
    input  logic a,
    input  logic b,
    output logic y
);
    logic a_reg, b_reg;
    logic nor_result;

    // 输入寄存器子模块
    InputRegister input_reg_inst (
        .clk    (clk),
        .a_in   (a),
        .b_in   (b),
        .a_reg  (a_reg),
        .b_reg  (b_reg)
    );

    // 逻辑运算子模块
    LogicOperation logic_op_inst (
        .a      (a_reg),
        .b      (b_reg),
        .result (nor_result)
    );

    // 输出寄存器子模块
    OutputRegister output_reg_inst (
        .clk      (clk),
        .data_in  (nor_result),
        .data_out (y)
    );
endmodule

// 输入寄存器子模块 - 负责对输入信号进行寄存
module InputRegister (
    input  logic clk,
    input  logic a_in,
    input  logic b_in,
    output logic a_reg,
    output logic b_reg
);
    always_ff @(posedge clk) begin
        a_reg <= a_in;
        b_reg <= b_in;
    end
endmodule

// 逻辑运算子模块 - 负责执行NOR逻辑操作
module LogicOperation (
    input  logic a,
    input  logic b,
    output logic result
);
    assign result = ~(a | b);
endmodule

// 输出寄存器子模块 - 负责将结果同步到输出端口
module OutputRegister (
    input  logic clk,
    input  logic data_in,
    output logic data_out
);
    always_ff @(posedge clk) begin
        data_out <= data_in;
    end
endmodule