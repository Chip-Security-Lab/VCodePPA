//SystemVerilog
///////////////////////////////////////////////////////////
// 顶层模块：4输入与门参数化实现（并行前缀结构）
///////////////////////////////////////////////////////////
module and_gate_4param #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] a,  // 输入 A
    input  wire [WIDTH-1:0] b,  // 输入 B
    input  wire [WIDTH-1:0] c,  // 输入 C
    input  wire [WIDTH-1:0] d,  // 输入 D
    output wire [WIDTH-1:0] y   // 输出 Y
);

    // 使用并行前缀结构处理4输入的与运算
    // 第一级：并行处理所有输入对
    wire [WIDTH-1:0] ab_result;
    wire [WIDTH-1:0] bc_result;
    wire [WIDTH-1:0] cd_result;
    
    // 并行计算所有可能的两输入组合
    parallel_and_unit #(
        .WIDTH(WIDTH)
    ) ab_and_inst (
        .a(a),
        .b(b),
        .y(ab_result)
    );
    
    parallel_and_unit #(
        .WIDTH(WIDTH)
    ) bc_and_inst (
        .a(b),
        .b(c),
        .y(bc_result)
    );
    
    parallel_and_unit #(
        .WIDTH(WIDTH)
    ) cd_and_inst (
        .a(c),
        .b(d),
        .y(cd_result)
    );
    
    // 第二级：合并结果
    wire [WIDTH-1:0] prefix_result;
    
    prefix_combiner #(
        .WIDTH(WIDTH)
    ) prefix_combine_inst (
        .a(ab_result),
        .b(bc_result),
        .c(cd_result),
        .y(y)
    );

endmodule

///////////////////////////////////////////////////////////
// 基本并行与门单元
///////////////////////////////////////////////////////////
module parallel_and_unit #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] a,  // 输入 A
    input  wire [WIDTH-1:0] b,  // 输入 B
    output wire [WIDTH-1:0] y   // 输出 Y
);

    // 实现基本并行与门操作
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_and_gates
            assign y[i] = a[i] & b[i];
        end
    endgenerate

endmodule

///////////////////////////////////////////////////////////
// 前缀组合器模块
///////////////////////////////////////////////////////////
module prefix_combiner #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] a,  // 第一对输入与的结果
    input  wire [WIDTH-1:0] b,  // 第二对输入与的结果
    input  wire [WIDTH-1:0] c,  // 第三对输入与的结果
    output wire [WIDTH-1:0] y   // 最终输出
);

    // 使用高效的前缀树结构组合结果
    wire [WIDTH-1:0] temp;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_prefix_combine
            // 使用前缀组合算法：(a&b&c&d) = a&((b&c)&d)
            assign temp[i] = a[i] & b[i];
            assign y[i] = temp[i] & c[i];
        end
    endgenerate

endmodule