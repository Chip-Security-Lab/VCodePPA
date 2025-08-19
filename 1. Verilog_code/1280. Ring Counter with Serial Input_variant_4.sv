//SystemVerilog
module serial_in_ring_counter(
    input wire clk,
    input wire rst,
    input wire ser_in,
    output wire [3:0] count
);
    // 将输出寄存器提前，使组合逻辑移动到寄存器之后
    reg ser_in_reg;
    reg [2:0] count_internal;
    
    // 寄存第一阶段：捕获输入和内部状态
    always @(posedge clk) begin
        ser_in_reg <= rst ? 1'b1 : ser_in;       // 使用条件运算符替代if-else
        count_internal <= rst ? 3'b000 : count[3:1];  // 使用条件运算符替代if-else
    end
    
    // 重定时后的输出组合逻辑
    assign count = {count_internal, ser_in_reg};
endmodule