//SystemVerilog
module shadow_reg_mask #(parameter DW=32) (
    input clk, en,
    input [DW-1:0] data_in, mask,
    output reg [DW-1:0] data_out
);
    reg [DW-1:0] shadow_reg;
    
    // 优化布尔表达式：使用条件选择代替位运算
    // 原始表达式：(shadow_reg & ~mask) | (data_in & mask)
    // 简化为每位的条件选择
    
    always @(posedge clk) begin
        if(en) begin
            for(int i=0; i<DW; i=i+1) begin
                shadow_reg[i] <= mask[i] ? data_in[i] : shadow_reg[i];
            end
        end
        data_out <= shadow_reg;
    end
endmodule