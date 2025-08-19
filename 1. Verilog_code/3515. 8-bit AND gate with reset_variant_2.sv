//SystemVerilog
// 顶层模块 - 8位带复位的AND门
module and_gate_8bit_reset (
    input wire [7:0] a,    // 8位输入A
    input wire [7:0] b,    // 8位输入B
    input wire rst,        // 复位信号
    output wire [7:0] y    // 8位输出Y
);
    // 内部连线
    wire [7:0] and_result;
    
    // 实例化基本AND操作子模块
    basic_and_operator and_op (
        .a(a),
        .b(b),
        .result(and_result)
    );
    
    // 实例化复位控制子模块
    reset_controller rst_ctrl (
        .data_in(and_result),
        .rst(rst),
        .data_out(y)
    );
    
endmodule

// 基本AND操作子模块
module basic_and_operator (
    input wire [7:0] a,      // 8位输入A
    input wire [7:0] b,      // 8位输入B
    output wire [7:0] result // 8位AND结果
);
    // 参数化位宽，提高可重用性
    parameter WIDTH = 8;
    
    // 纯组合逻辑实现AND操作
    assign result = a & b;
    
endmodule

// 复位控制子模块
module reset_controller (
    input wire [7:0] data_in,  // 输入数据
    input wire rst,            // 复位信号
    output reg [7:0] data_out  // 带复位控制的输出数据
);
    // 参数化位宽和复位值
    parameter WIDTH = 8;
    parameter RESET_VALUE = {WIDTH{1'b0}};
    
    // 复位控制逻辑
    always @(*) begin
        if (rst) begin
            data_out = RESET_VALUE;
        end else begin
            data_out = data_in;
        end
    end
    
endmodule