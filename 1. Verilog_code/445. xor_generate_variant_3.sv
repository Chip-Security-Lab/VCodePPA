//SystemVerilog - IEEE 1364-2005
// 顶层模块 - 流水线化的XOR运算器
module xor_generate #(
    parameter WIDTH = 4
)(
    input wire clk,                 // 时钟信号
    input wire rst_n,               // 复位信号，低有效
    input wire [WIDTH-1:0] a,       // 输入数据A
    input wire [WIDTH-1:0] b,       // 输入数据B
    output wire [WIDTH-1:0] y       // 输出结果
);

    // 流水线寄存器声明
    reg [WIDTH-1:0] a_reg, b_reg;   // 输入寄存器
    reg [WIDTH-1:0] result_reg;     // 结果寄存器
    
    // 第一级流水线 - 输入数据缓存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= {WIDTH{1'b0}};
            b_reg <= {WIDTH{1'b0}};
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // 数据通路声明
    wire [WIDTH-1:0] xor_result_wire;
    
    // 实例化中间XOR运算核心
    xor_compute_core #(
        .WIDTH(WIDTH)
    ) xor_core_inst (
        .a_data(a_reg),
        .b_data(b_reg),
        .result(xor_result_wire)
    );
    
    // 第二级流水线 - 结果寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= {WIDTH{1'b0}};
        end else begin
            result_reg <= xor_result_wire;
        end
    end
    
    // 最终输出赋值
    assign y = result_reg;
    
endmodule

// 中间计算核心模块 - 并行XOR数据通路
module xor_compute_core #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] a_data,
    input wire [WIDTH-1:0] b_data,
    output wire [WIDTH-1:0] result
);
    // 优化的数据通路 - 以块为单位进行XOR运算
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i+1) begin : xor_bit_gen
            // 实例化优化后的XOR单元
            xor_bit_unit bit_unit (
                .a_bit(a_data[i]),
                .b_bit(b_data[i]),
                .y_bit(result[i])
            );
        end
    endgenerate
endmodule

// 优化的单比特XOR运算单元
module xor_bit_unit (
    input wire a_bit,
    input wire b_bit,
    output wire y_bit
);
    // 直接计算XOR结果，移除多余的内部连线
    assign y_bit = a_bit ^ b_bit;
endmodule