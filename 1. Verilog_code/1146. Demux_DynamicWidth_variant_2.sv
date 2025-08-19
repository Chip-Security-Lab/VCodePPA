//SystemVerilog
module Demux_DynamicWidth #(parameter MAX_DW=32) (
    input wire clk,
    input wire [5:0] width_config,
    input wire [MAX_DW-1:0] data_in,
    output reg [3:0][MAX_DW-1:0] data_out
);
    // 预计算掩码
    reg [MAX_DW-1:0] mask_reg;
    reg [5:0] effective_width;
    
    always @(posedge clk) begin
        // 计算有效宽度 - 避免使用条件运算符
        effective_width <= (width_config >= MAX_DW) ? MAX_DW[5:0] : width_config;
        
        // 使用移位和减法优化掩码计算
        mask_reg <= ({{(MAX_DW-1){1'b0}}, 1'b1} << effective_width) - 1'b1;
        
        // 使用布尔代数简化数据分解
        // data_out[0] = data_in & mask_reg (保持不变)
        // data_out[1] = data_in & ~mask_reg (应用德摩根定律)
        data_out[0] <= data_in & mask_reg;
        data_out[1] <= data_in & ~mask_reg;
        
        // 直接赋值0，避免不必要的逻辑
        data_out[2] <= {MAX_DW{1'b0}};
        data_out[3] <= {MAX_DW{1'b0}};
    end
endmodule