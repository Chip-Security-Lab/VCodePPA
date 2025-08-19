//SystemVerilog
// IEEE 1364-2005 Verilog标准
module param_shadow_reg #(
    parameter DWIDTH = 32,
    parameter RESET_VAL = 0
)(
    input wire clk,
    input wire rst,
    input wire [DWIDTH-1:0] data,
    input wire shadow_trigger,
    output reg [DWIDTH-1:0] shadow
);
    // 移动寄存器以平衡逻辑路径
    reg [DWIDTH-1:0] data_reg;
    reg shadow_trigger_reg;
    reg shadow_en;
    
    // 将输入数据寄存一级，减少输入到工作寄存器的路径
    always @(posedge clk) begin
        if (rst)
            data_reg <= RESET_VAL;
        else
            data_reg <= data;
    end
    
    // 寄存触发信号，拆分时序路径
    always @(posedge clk) begin
        shadow_trigger_reg <= shadow_trigger;
    end
    
    // 将使能计算前置，形成预计算逻辑
    always @(posedge clk) begin
        shadow_en <= shadow_trigger_reg & ~rst;
    end
    
    // 直接使用data_reg更新shadow，减少从工作寄存器到输出的路径长度
    always @(posedge clk) begin
        if (rst)
            shadow <= RESET_VAL;
        else if (shadow_en)
            shadow <= data_reg;
    end
endmodule