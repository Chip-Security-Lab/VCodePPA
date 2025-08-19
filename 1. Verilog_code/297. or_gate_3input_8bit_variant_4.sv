//SystemVerilog
// 顶层模块 - 3输入8位OR门
module or_gate_3input_8bit #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire [WIDTH-1:0] c,
    output wire [WIDTH-1:0] y
);
    // 内部连线
    wire [WIDTH-1:0] ab_or;
    
    // 实例化第一阶段OR运算
    or_stage or_stage_ab (
        .in1(a),
        .in2(b),
        .out(ab_or)
    );
    
    // 实例化第二阶段OR运算
    or_stage or_stage_abc (
        .in1(ab_or),
        .in2(c),
        .out(y)
    );
endmodule

// 单阶段OR操作模块
module or_stage #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] in1,
    input wire [WIDTH-1:0] in2,
    output wire [WIDTH-1:0] out
);
    // 逐位或操作
    bit_operation #(
        .WIDTH(WIDTH),
        .OPERATION("OR")
    ) or_op (
        .a(in1),
        .b(in2),
        .y(out)
    );
endmodule

// 通用位操作模块 - 支持不同的位级操作
module bit_operation #(
    parameter WIDTH = 8,
    parameter OPERATION = "OR"  // 可扩展为其他操作
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] y
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : bit_ops
            if (OPERATION == "OR") begin : gen_or
                or or_inst (y[i], a[i], b[i]);
            end
            else if (OPERATION == "AND") begin : gen_and
                and and_inst (y[i], a[i], b[i]);
            end
            else if (OPERATION == "XOR") begin : gen_xor
                xor xor_inst (y[i], a[i], b[i]);
            end
            // 可以添加更多操作类型
        end
    endgenerate
endmodule