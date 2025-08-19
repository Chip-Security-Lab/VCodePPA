//SystemVerilog
// SystemVerilog
module Demux_TriState #(parameter DW=8, N=4) (
    inout [DW-1:0] bus,
    input [N-1:0] sel,
    input oe,
    output reg [N-1:0][DW-1:0] rx_data,
    input [N-1:0][DW-1:0] tx_data
);
    // 使用IEEE 1364-2005 Verilog标准
    
    // 驱动总线的三态逻辑
    reg [DW-1:0] bus_out;
    
    // 将条件运算符转换为完整的if-else赋值
    assign bus = bus_out;
    
    always @(*) begin
        if (oe) begin
            bus_out = tx_data[sel];
        end
        else begin
            bus_out = {DW{1'bz}};
        end
    end
    
    // 从总线接收数据的逻辑
    integer i;
    always @(*) begin
        // 初始化rx_data，避免锁存器
        for (i = 0; i < N; i = i + 1) begin
            rx_data[i] = {DW{1'b0}};
        end
        
        // 只对选中的通道赋值
        if (sel < N) begin
            rx_data[sel] = bus;
        end
    end
endmodule