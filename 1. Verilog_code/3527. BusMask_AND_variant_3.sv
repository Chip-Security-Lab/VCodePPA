//SystemVerilog
//========================================================================
// 顶层模块: 总线掩码处理系统 (IEEE 1364-2005 Verilog)
//========================================================================
module BusMask_AND #(
    parameter BUS_WIDTH = 16,         // 总线宽度参数化
    parameter OP_TYPE   = "AND"       // 操作类型参数化
)(
    input  wire [BUS_WIDTH-1:0] bus_in,     // 输入总线
    input  wire [BUS_WIDTH-1:0] mask,       // 掩码输入
    output wire [BUS_WIDTH-1:0] masked_bus  // 掩码处理后的输出
);

    // 直接连接逻辑，移除不必要的内部信号，减少资源使用
    wire [BUS_WIDTH-1:0] operation_result;
    
    // 位运算核心模块 - 直接连接到输入和输出
    BitOperationCore #(
        .DATA_WIDTH(BUS_WIDTH),
        .OPERATION(OP_TYPE)
    ) bit_operation (
        .data_a(bus_in),       // 直接使用输入总线，移除预处理
        .data_b(mask),         // 直接使用掩码输入，移除预处理
        .result(masked_bus)    // 直接输出到masked_bus，移除后处理
    );
    
endmodule

//========================================================================
// 位运算核心模块: 执行可配置的位运算操作
//========================================================================
module BitOperationCore #(
    parameter DATA_WIDTH = 16,
    parameter OPERATION = "AND"  // 支持的操作类型: "AND", "OR", "XOR"
)(
    input  wire [DATA_WIDTH-1:0] data_a,
    input  wire [DATA_WIDTH-1:0] data_b,
    output wire [DATA_WIDTH-1:0] result
);

    // 使用条件操作符直接实现位运算，减少模块层次和资源使用
    generate
        if (OPERATION == "AND") begin: and_operation
            assign result = data_a & data_b;
        end
        else if (OPERATION == "OR") begin: or_operation
            assign result = data_a | data_b;
        end
        else if (OPERATION == "XOR") begin: xor_operation
            assign result = data_a ^ data_b;
        end
        else begin: default_operation
            // 默认为AND操作
            assign result = data_a & data_b;
        end
    endgenerate

endmodule