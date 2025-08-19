//SystemVerilog
//IEEE 1364-2005 Verilog标准
// 顶层模块 - 8位与门延迟操作
module and_gate_8_delay (
    input  wire [7:0] a,    // 8-bit input A
    input  wire [7:0] b,    // 8-bit input B
    output wire [7:0] y     // 8-bit output Y
);
    // 内部信号
    wire [7:0] and_result;

    // 实例化位操作单元
    bit_operation_unit #(
        .WIDTH(8),
        .OPERATION("AND")
    ) bit_op_inst (
        .operand_a(a),
        .operand_b(b),
        .result(and_result)
    );
    
    // 实例化可配置延迟处理器
    configurable_delay_processor #(
        .WIDTH(8),
        .DELAY_TYPE("FIXED"),
        .DELAY_VALUE(5)
    ) delay_inst (
        .clk(1'b0),          // 不使用时钟
        .rst_n(1'b1),        // 不使用复位
        .enable(1'b1),       // 始终启用
        .data_in(and_result),
        .data_out(y)
    );
    
endmodule

// 位操作单元 - 支持多种位运算
module bit_operation_unit #(
    parameter WIDTH = 8,
    parameter OPERATION = "AND"  // 支持: "AND", "OR", "XOR", "NAND"
)(
    input  wire [WIDTH-1:0] operand_a,
    input  wire [WIDTH-1:0] operand_b,
    output reg  [WIDTH-1:0] result
);
    // 基于参数执行选定的位操作
    always @(*) begin
        case (OPERATION)
            "AND":  result = operand_a & operand_b;
            "OR":   result = operand_a | operand_b;
            "XOR":  result = operand_a ^ operand_b;
            "NAND": result = ~(operand_a & operand_b);
            default: result = operand_a & operand_b; // 默认为AND操作
        endcase
    end
    
endmodule

// 可配置延迟处理器
module configurable_delay_processor #(
    parameter WIDTH = 8,
    parameter DELAY_TYPE = "FIXED",   // "FIXED", "VARIABLE", "NONE"
    parameter DELAY_VALUE = 5         // 延迟时间单位
)(
    input  wire clk,                  // 时钟（用于同步延迟模式）
    input  wire rst_n,                // 异步复位（低电平有效）
    input  wire enable,               // 模块使能信号
    input  wire [WIDTH-1:0] data_in,  // 输入数据
    output reg  [WIDTH-1:0] data_out  // 延迟后的输出
);
    // 管理数据延迟和输出
    always @(*) begin
        if (enable) begin
            case (DELAY_TYPE)
                "FIXED": begin
                    #DELAY_VALUE data_out = data_in;
                end
                "VARIABLE": begin
                    // 在可变延迟模式下可以添加额外逻辑
                    #(DELAY_VALUE + (|data_in)) data_out = data_in;
                end
                "NONE": begin
                    data_out = data_in; // 无延迟直通
                end
                default: begin
                    #DELAY_VALUE data_out = data_in; // 默认为固定延迟
                end
            endcase
        end
        else begin
            data_out = {WIDTH{1'b0}}; // 未启用时输出全零
        end
    end
    
endmodule