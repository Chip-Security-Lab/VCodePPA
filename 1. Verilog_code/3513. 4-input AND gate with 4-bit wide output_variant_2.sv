//SystemVerilog
// 顶层模块: 多输入与门系统 (4-bit 宽)
module and_gate_system #(
    parameter WIDTH = 4,            // 位宽参数
    parameter PIPELINE_ENABLE = 1   // 流水线使能参数
)(
    input wire [WIDTH-1:0] a,       // 输入 A
    input wire [WIDTH-1:0] b,       // 输入 B
    input wire [WIDTH-1:0] c,       // 输入 C
    input wire [WIDTH-1:0] d,       // 输入 D
    input wire clk,                 // 时钟信号
    input wire rst_n,               // 复位信号
    output wire [WIDTH-1:0] y       // 输出 Y
);
    // 阶段1: 一级与门操作的内部信号
    wire [WIDTH-1:0] ab_result;
    wire [WIDTH-1:0] cd_result;
    
    // 阶段2: 流水线寄存器输出
    wire [WIDTH-1:0] ab_reg;
    wire [WIDTH-1:0] cd_reg;
    
    // 实例化第一级并行与门单元
    parallel_and_unit #(
        .WIDTH(WIDTH)
    ) first_level_and_unit (
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .ab_result(ab_result),
        .cd_result(cd_result)
    );
    
    // 实例化可选的流水线寄存器单元
    pipeline_register_unit #(
        .WIDTH(WIDTH),
        .ENABLE(PIPELINE_ENABLE)
    ) pipeline_unit (
        .clk(clk),
        .rst_n(rst_n),
        .ab_in(ab_result),
        .cd_in(cd_result),
        .ab_out(ab_reg),
        .cd_out(cd_reg)
    );
    
    // 实例化最终输出与门单元
    final_and_unit #(
        .WIDTH(WIDTH)
    ) output_and_unit (
        .ab(ab_reg),
        .cd(cd_reg),
        .result(y)
    );
endmodule

// 并行第一级与门单元
module parallel_and_unit #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire [WIDTH-1:0] c,
    input wire [WIDTH-1:0] d,
    output wire [WIDTH-1:0] ab_result,
    output wire [WIDTH-1:0] cd_result
);
    // 并行执行两个与操作
    basic_and_operator #(.WIDTH(WIDTH)) ab_and (
        .in1(a),
        .in2(b),
        .out(ab_result)
    );
    
    basic_and_operator #(.WIDTH(WIDTH)) cd_and (
        .in1(c),
        .in2(d),
        .out(cd_result)
    );
endmodule

// 流水线寄存器单元
module pipeline_register_unit #(
    parameter WIDTH = 4,
    parameter ENABLE = 1
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] ab_in,
    input wire [WIDTH-1:0] cd_in,
    output wire [WIDTH-1:0] ab_out,
    output wire [WIDTH-1:0] cd_out
);
    // 使用参数化的流水线寄存器
    generate
        if (ENABLE) begin: gen_pipeline
            // 带复位的流水线寄存器
            reg [WIDTH-1:0] ab_reg;
            reg [WIDTH-1:0] cd_reg;
            
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    ab_reg <= {WIDTH{1'b0}};
                    cd_reg <= {WIDTH{1'b0}};
                end else begin
                    ab_reg <= ab_in;
                    cd_reg <= cd_in;
                end
            end
            
            assign ab_out = ab_reg;
            assign cd_out = cd_reg;
        end else begin: gen_no_pipeline
            // 无流水线时的直通连接
            assign ab_out = ab_in;
            assign cd_out = cd_in;
        end
    endgenerate
endmodule

// 最终输出与门单元
module final_and_unit #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] ab,
    input wire [WIDTH-1:0] cd,
    output wire [WIDTH-1:0] result
);
    // 执行最终的与操作
    basic_and_operator #(.WIDTH(WIDTH)) final_and (
        .in1(ab),
        .in2(cd),
        .out(result)
    );
endmodule

// 基本与门运算器
module basic_and_operator #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] in1,
    input wire [WIDTH-1:0] in2,
    output wire [WIDTH-1:0] out
);
    // 可合成为专用宏单元的高效AND实现
    assign out = in1 & in2;
endmodule