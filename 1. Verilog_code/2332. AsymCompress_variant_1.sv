//SystemVerilog
// 顶层模块
module AsymCompress #(
    parameter IN_W = 64,
    parameter OUT_W = 32
) (
    input [IN_W-1:0] din,
    output [OUT_W-1:0] dout
);
    // 内部连接信号
    wire [OUT_W-1:0] compression_result;
    wire [7:0] subtraction_result;
    wire [7:0] operand_a, operand_b;
    
    // 从输入数据中提取8位操作数
    assign operand_a = din[7:0];
    assign operand_b = din[15:8];
    
    // 实例化压缩运算子模块
    DataCompressor #(
        .IN_W(IN_W),
        .OUT_W(OUT_W)
    ) compressor_inst (
        .data_in(din),
        .subtraction_result(subtraction_result),
        .compressed_out(compression_result)
    );
    
    // 实例化先行借位减法器
    CarryLookAheadSubtractor #(
        .WIDTH(8)
    ) subtractor_inst (
        .a(operand_a),
        .b(operand_b),
        .result(subtraction_result)
    );
    
    // 将压缩结果连接到输出
    assign dout = compression_result;
    
endmodule

// 数据压缩子模块
module DataCompressor #(
    parameter IN_W = 64,
    parameter OUT_W = 32
) (
    input [IN_W-1:0] data_in,
    input [7:0] subtraction_result,
    output [OUT_W-1:0] compressed_out
);
    reg [OUT_W-1:0] result;
    integer i;
    
    always @(*) begin
        result = {OUT_W{1'b0}};
        for(i=0; i<IN_W/OUT_W; i=i+1) begin
            result = result ^ data_in[i*OUT_W +: OUT_W];
        end
        // 整合减法器结果到压缩数据中
        result[7:0] = result[7:0] ^ subtraction_result;
    end
    
    assign compressed_out = result;
    
endmodule

// 8位先行借位减法器
module CarryLookAheadSubtractor #(
    parameter WIDTH = 8
) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] result
);
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] diff;
    wire [WIDTH-1:0] p; // 传播信号
    wire [WIDTH-1:0] g; // 生成信号
    
    // 初始化借位信号
    assign borrow[0] = 1'b0;
    
    // 计算传播和生成信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_pg
            assign p[i] = ~a[i]; // 传播信号
            assign g[i] = ~a[i] & b[i]; // 生成信号
        end
    endgenerate
    
    // 计算借位信号
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_borrow
            assign borrow[i+1] = g[i] | (p[i] & borrow[i]);
        end
    endgenerate
    
    // 计算差值
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_diff
            assign diff[i] = a[i] ^ b[i] ^ borrow[i];
        end
    endgenerate
    
    // 输出结果
    assign result = diff;
    
endmodule