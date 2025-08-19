//SystemVerilog
// 顶层模块: 3输入4位OR门阵列
module or_gate_3input_4bit_always (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire [3:0] c,
    output wire [3:0] y
);
    // 使用参数化设计，增强可配置性
    or_gate_vector_tree #(
        .DATA_WIDTH(4),
        .INPUT_COUNT(3)
    ) or_tree_inst (
        .inputs({a, b, c}),  // 打包输入为单个向量
        .result(y)
    );
endmodule

// 参数化向量OR树结构
// 可配置数据宽度和输入数量，提高可复用性
module or_gate_vector_tree #(
    parameter DATA_WIDTH = 4,    // 每个输入的数据宽度
    parameter INPUT_COUNT = 3    // 输入数量
)(
    input  wire [DATA_WIDTH*INPUT_COUNT-1:0] inputs,
    output wire [DATA_WIDTH-1:0] result
);
    // 内部信号声明
    wire [DATA_WIDTH-1:0] stage_results[INPUT_COUNT-1:0];
    
    // 第一阶段初始化
    assign stage_results[0] = inputs[DATA_WIDTH-1:0];
    
    // 树形OR级联结构，减少关键路径
    genvar stage;
    generate
        for (stage = 1; stage < INPUT_COUNT; stage = stage + 1) begin : stage_gen
            // 从输入向量提取当前输入
            wire [DATA_WIDTH-1:0] current_input = 
                inputs[DATA_WIDTH*(stage+1)-1:DATA_WIDTH*stage];
            
            // 对每个位进行并行处理，使用位级运算单元
            bit_vector_logic #(
                .WIDTH(DATA_WIDTH),
                .OPERATION("OR")
            ) bit_logic_inst (
                .a(stage_results[stage-1]),
                .b(current_input),
                .y(stage_results[stage])
            );
        end
    endgenerate
    
    // 将最终结果连接到输出
    assign result = stage_results[INPUT_COUNT-1];
endmodule

// 可配置位向量逻辑运算单元
// 支持不同的位级逻辑操作
module bit_vector_logic #(
    parameter WIDTH = 4,
    parameter OPERATION = "OR"  // 支持扩展为其他逻辑运算
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] y
);
    // 位级并行处理
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : bit_op_gen
            // 根据参数选择操作
            // 使用连续赋值以减少逻辑层级
            if (OPERATION == "OR") begin : or_op
                assign y[i] = a[i] | b[i];
            end
            else if (OPERATION == "AND") begin : and_op
                assign y[i] = a[i] & b[i];
            end
            else if (OPERATION == "XOR") begin : xor_op
                assign y[i] = a[i] ^ b[i];
            end
            else begin : default_op
                // 默认为OR操作
                assign y[i] = a[i] | b[i];
            end
        end
    endgenerate
endmodule