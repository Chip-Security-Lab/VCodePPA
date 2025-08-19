//SystemVerilog
// 顶层模块 - 8位2输入或门
module or_gate_2input_8bit_forloop (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] y
);
    // 生成多个4位或门模块实例
    genvar i;
    generate
        for (i = 0; i < 2; i = i + 1) begin: or_4bit_gen
            or_gate_2input_4bit or_4bit_inst (
                .a_in(a[i*4+3:i*4]),
                .b_in(b[i*4+3:i*4]),
                .y_out(y[i*4+3:i*4])
            );
        end
    endgenerate
endmodule

// 中间层模块：4位或门运算
module or_gate_2input_4bit (
    input  wire [3:0] a_in,
    input  wire [3:0] b_in,
    output wire [3:0] y_out
);
    // 参数化配置，允许可扩展性
    parameter WIDTH = 4;
    
    // 使用for循环生成多个2位或门
    genvar j;
    generate
        for (j = 0; j < WIDTH/2; j = j + 1) begin: or_2bit_gen
            or_gate_2input_2bit or_2bit_inst (
                .a_in(a_in[j*2+1:j*2]),
                .b_in(b_in[j*2+1:j*2]),
                .y_out(y_out[j*2+1:j*2])
            );
        end
    endgenerate
endmodule

// 子模块：2位或门运算 - 优化实现
module or_gate_2input_2bit (
    input  wire [1:0] a_in,
    input  wire [1:0] b_in,
    output wire [1:0] y_out
);
    // 直接使用位运算符，避免实例化额外的模块
    // 这样可以减少层次和信号延迟
    assign y_out = a_in | b_in;
endmodule