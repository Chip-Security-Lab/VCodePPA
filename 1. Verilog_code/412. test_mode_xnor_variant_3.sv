//SystemVerilog
// 顶层模块 - 集成测试模式与逻辑运算功能
module test_mode_xnor #(
    parameter MODE_DEFAULT = 1'b0
)(
    input  wire clk,        // 系统时钟
    input  wire rst_n,      // 低电平有效复位
    input  wire test_mode,  // 测试模式选择
    input  wire a,          // 操作数A
    input  wire b,          // 操作数B
    output wire y           // 最终输出
);
    // 内部信号定义
    wire logic_result;      // 逻辑运算结果
    wire mux_out;           // 多路选择器输出
    
    // 实例化逻辑运算子模块
    logic_operation_unit #(
        .OPERATION_TYPE(1)  // 1表示XNOR操作
    ) logic_unit (
        .clk        (clk),
        .rst_n      (rst_n),
        .operand_a  (a),
        .operand_b  (b),
        .result     (logic_result)
    );
    
    // 实例化输出控制子模块
    output_control output_ctrl (
        .clk        (clk),
        .rst_n      (rst_n),
        .test_mode  (test_mode),
        .data_in    (logic_result),
        .data_out   (y)
    );
    
endmodule

// 通用逻辑运算子模块
module logic_operation_unit #(
    parameter OPERATION_TYPE = 1  // 0=AND, 1=XNOR, 2=OR, 3=XOR
)(
    input  wire clk,          // 系统时钟
    input  wire rst_n,        // 低电平有效复位
    input  wire operand_a,    // 第一个操作数
    input  wire operand_b,    // 第二个操作数
    output wire result        // 运算结果
);
    // 内部信号
    reg  operation_result;
    
    // 基于参数选择逻辑运算类型
    always @(*) begin
        case (OPERATION_TYPE)
            0: operation_result = operand_a & operand_b;    // AND
            1: operation_result = ~(operand_a ^ operand_b); // XNOR
            2: operation_result = operand_a | operand_b;    // OR
            3: operation_result = operand_a ^ operand_b;    // XOR
            default: operation_result = ~(operand_a ^ operand_b); // 默认XNOR
        endcase
    end
    
    // 输出赋值
    assign result = operation_result;
    
endmodule

// 输出控制子模块
module output_control (
    input  wire clk,       // 系统时钟
    input  wire rst_n,     // 低电平有效复位
    input  wire test_mode, // 测试模式控制信号
    input  wire data_in,   // 数据输入
    output reg  data_out   // 数据输出
);
    // 测试模式控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0; // 复位时输出置零
        end else begin
            data_out <= test_mode ? data_in : 1'b0; // 测试模式选择
        end
    end
    
endmodule