//SystemVerilog
module CascadeOR(
    input wire [2:0] in,
    input wire clk,
    input wire rst_n,
    output reg out
);
    // 流水线寄存器
    reg stage1_result;
    reg stage2_result;
    
    // 组合所有流水线阶段的逻辑到单个always块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_result <= 1'b0;
            stage2_result <= 1'b0;
            out <= 1'b0;
        end 
        else begin
            stage1_result <= in[0] | in[1];
            stage2_result <= stage1_result | in[2];
            out <= stage2_result;
        end
    end
    
endmodule