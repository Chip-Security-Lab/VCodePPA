//SystemVerilog
module shadow_reg_mask #(parameter DW=32) (
    input clk, en,
    input [DW-1:0] data_in, mask,
    output reg [DW-1:0] data_out
);
    reg [DW-1:0] shadow_reg;
    
    always @(posedge clk) begin
        if(en) begin
            // 优化布尔表达式：(shadow_reg & ~mask) | (data_in & mask)
            // 等价于：shadow_reg ^ ((shadow_reg ^ data_in) & mask)
            shadow_reg <= shadow_reg ^ ((shadow_reg ^ data_in) & mask);
        end
        data_out <= shadow_reg;
    end
endmodule