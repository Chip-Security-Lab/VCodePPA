//SystemVerilog
// 顶层模块
module sync_arithmetic_right_shifter #(
    parameter DW = 32,  // Data width
    parameter SW = 5    // Shift width
)(
    input                  clk_i,
    input                  en_i,
    input      [DW-1:0]    data_i,
    input      [SW-1:0]    shift_i,
    output     [DW-1:0]    data_o
);
    // 内部连接信号
    wire [DW-1:0] shift_result;
    
    // 算术右移运算子模块实例化
    arithmetic_shift_unit #(
        .DATA_WIDTH(DW),
        .SHIFT_WIDTH(SW)
    ) shift_unit (
        .data_i(data_i),
        .shift_i(shift_i),
        .result_o(shift_result)
    );
    
    // 同步寄存器子模块实例化
    output_register #(
        .WIDTH(DW)
    ) out_reg (
        .clk_i(clk_i),
        .en_i(en_i),
        .data_i(shift_result),
        .data_o(data_o)
    );
    
endmodule

// 算术右移运算子模块
module arithmetic_shift_unit #(
    parameter DATA_WIDTH = 32,
    parameter SHIFT_WIDTH = 5
)(
    input      [DATA_WIDTH-1:0]    data_i,
    input      [SHIFT_WIDTH-1:0]   shift_i,
    output     [DATA_WIDTH-1:0]    result_o
);
    // 实现纯组合逻辑的算术右移
    assign result_o = $signed(data_i) >>> shift_i;
    
endmodule

// 同步寄存器子模块
module output_register #(
    parameter WIDTH = 32
)(
    input                  clk_i,
    input                  en_i,
    input      [WIDTH-1:0] data_i,
    output reg [WIDTH-1:0] data_o
);
    // 使用使能信号的同步寄存器
    always @(posedge clk_i) begin
        if (en_i) begin
            data_o <= data_i;
        end
    end
    
endmodule