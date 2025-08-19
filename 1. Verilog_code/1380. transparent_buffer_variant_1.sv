//SystemVerilog
// 顶层模块
module transparent_buffer (
    input wire [7:0] data_in,
    input wire enable,
    output wire [7:0] data_out
);
    // 直接在顶层实现逻辑，减少层次结构
    assign data_out = enable ? data_in : 8'b0;
endmodule