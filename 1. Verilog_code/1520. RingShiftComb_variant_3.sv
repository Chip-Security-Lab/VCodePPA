//SystemVerilog
// IEEE 1364-2005 Verilog标准
// 顶层模块
module RingShiftComb #(
    parameter RING_SIZE = 5
)(
    input wire clk,
    input wire rotate,
    output wire [RING_SIZE-1:0] ring_out
);
    // 内部连线
    wire [RING_SIZE-1:0] next_ring_value;
    reg [RING_SIZE-1:0] current_ring_value;
    reg rotate_reg;
    
    // 寄存器更新逻辑 - 将寄存器移到组合逻辑之后
    initial begin
        current_ring_value = {{(RING_SIZE-1){1'b0}}, 1'b1}; // 初始化为5'b00001的参数化写法
        rotate_reg = 1'b0;
    end
    
    // 寄存输入信号rotate
    always @(posedge clk) begin
        rotate_reg <= rotate;
    end
    
    // 移位逻辑 - 现在直接在顶层实现
    assign next_ring_value = rotate_reg ? {current_ring_value[0], current_ring_value[RING_SIZE-1:1]} : current_ring_value;
    
    // 寄存器更新
    always @(posedge clk) begin
        current_ring_value <= next_ring_value;
    end
    
    // 输出赋值
    assign ring_out = current_ring_value;
    
endmodule