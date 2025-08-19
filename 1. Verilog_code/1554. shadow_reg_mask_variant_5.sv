//SystemVerilog
module shadow_reg_mask #(parameter DW=32) (
    input clk, en,
    input [DW-1:0] data_in, mask,
    output reg [DW-1:0] data_out
);
    reg [DW-1:0] shadow_reg;
    
    always @(posedge clk) begin
        if(en) begin
            // 简化布尔表达式：使用mask作为选择信号直接选择数据位
            // 对于mask为1的位，选择data_in；对于mask为0的位，保留shadow_reg
            for(integer i=0; i<DW; i=i+1) begin
                shadow_reg[i] <= mask[i] ? data_in[i] : shadow_reg[i];
            end
        end
        data_out <= shadow_reg;
    end
endmodule