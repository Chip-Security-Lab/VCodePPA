//SystemVerilog
module Demux_DynamicWidth #(
    parameter MAX_DW = 32
)(
    input                      clk,
    input      [5:0]           width_config,
    input      [MAX_DW-1:0]    data_in,
    output reg [3:0][MAX_DW-1:0] data_out
);
    // 流水线寄存器 - 第一级：输入数据和配置寄存
    reg [MAX_DW-1:0] data_in_reg;
    reg [5:0]        width_config_reg;
    
    // 流水线寄存器 - 第二级：掩码计算
    reg [MAX_DW-1:0] mask_reg;
    reg [MAX_DW-1:0] data_stage2;
    
    // 掩码生成逻辑
    wire [MAX_DW-1:0] mask_gen = (1 << width_config_reg) - 1;
    
    // 合并所有时钟上升沿触发的always块
    always @(posedge clk) begin
        // 流水线第一级 - 输入寄存
        data_in_reg <= data_in;
        width_config_reg <= width_config;
        
        // 流水线第二级 - 掩码计算
        mask_reg <= mask_gen;
        data_stage2 <= data_in_reg;
        
        // 流水线第三级 - 数据分流
        data_out[0] <= data_stage2 & mask_reg;
        data_out[1] <= data_stage2 & ~mask_reg;
        data_out[2] <= '0; // 未使用的输出端口清零
        data_out[3] <= '0; // 未使用的输出端口清零
    end

endmodule