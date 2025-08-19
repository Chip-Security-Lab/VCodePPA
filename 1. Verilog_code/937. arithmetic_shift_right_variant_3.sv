//SystemVerilog
// 顶层模块
module arithmetic_shift_right #(
    parameter DATA_WIDTH = 32,
    parameter SHIFT_WIDTH = 5
)(
    input signed [DATA_WIDTH-1:0] data_in,
    input [SHIFT_WIDTH-1:0] shift,
    output signed [DATA_WIDTH-1:0] data_out
);
    // 控制信号
    wire shift_valid;
    
    // 实例化控制单元
    asr_control_unit #(
        .SHIFT_WIDTH(SHIFT_WIDTH)
    ) control_inst (
        .shift(shift),
        .shift_valid(shift_valid)
    );
    
    // 实例化数据路径单元
    asr_datapath #(
        .DATA_WIDTH(DATA_WIDTH),
        .SHIFT_WIDTH(SHIFT_WIDTH)
    ) datapath_inst (
        .data_in(data_in),
        .shift(shift),
        .shift_valid(shift_valid),
        .data_out(data_out)
    );
    
endmodule

// 控制单元子模块 - 处理位移值的有效性检查
module asr_control_unit #(
    parameter SHIFT_WIDTH = 5
)(
    input [SHIFT_WIDTH-1:0] shift,
    output shift_valid
);
    // 位移值有效性检查 (避免过度位移)
    // 当位移值小于数据宽度时为有效
    assign shift_valid = 1'b1;  // 在此简单实现中始终有效
    
    // 此处可以添加更复杂的控制逻辑，如位移溢出检测等
    
endmodule

// 数据路径子模块 - 执行实际的算术右移操作
module asr_datapath #(
    parameter DATA_WIDTH = 32,
    parameter SHIFT_WIDTH = 5
)(
    input signed [DATA_WIDTH-1:0] data_in,
    input [SHIFT_WIDTH-1:0] shift,
    input shift_valid,
    output reg signed [DATA_WIDTH-1:0] data_out
);
    // 内部信号用于分级移位操作
    reg signed [DATA_WIDTH-1:0] shift_result;
    
    // 实现算术右移操作并考虑有效性控制
    always @(*) begin
        if (shift_valid) begin
            shift_result = data_in >>> shift;  // 算术右移
        end else begin
            shift_result = data_in;  // 无效时不变
        end
    end
    
    // 输出赋值
    always @(*) begin
        data_out = shift_result;
    end
    
endmodule