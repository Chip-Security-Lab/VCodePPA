//SystemVerilog
module basic_right_shift #(parameter WIDTH = 8) (
    input  wire clk,
    input  wire reset_n,
    input  wire serial_in,
    output wire serial_out
);
    // 将寄存器分为两个部分，形成浅层的流水线结构
    reg [WIDTH/2-1:0] shift_reg_high;
    reg [WIDTH/2-1:0] shift_reg_low;
    
    // 高位寄存器逻辑 - 接收输入数据
    always @(posedge clk) begin
        if (!reset_n)
            shift_reg_high <= {(WIDTH/2){1'b0}};
        else
            shift_reg_high <= {serial_in, shift_reg_high[WIDTH/2-1:1]};
    end
    
    // 低位寄存器逻辑 - 接收高位寄存器数据并输出
    always @(posedge clk) begin
        if (!reset_n)
            shift_reg_low <= {(WIDTH/2){1'b0}};
        else
            shift_reg_low <= {shift_reg_high[0], shift_reg_low[WIDTH/2-1:1]};
    end
    
    // 输出赋值
    assign serial_out = shift_reg_low[0];
endmodule