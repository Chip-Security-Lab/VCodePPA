//SystemVerilog
module Sync_XNOR(
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire [7:0] sig_a, sig_b,
    output wire valid_out,
    output wire [7:0] q
);

    // 输入和中间信号寄存器
    reg [7:0] sig_a_reg, sig_b_reg;
    reg valid_reg;
    
    // 寄存组合逻辑结果
    reg [7:0] xnor_result;
    reg valid_out_reg;
    
    // 输入信号寄存
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            sig_a_reg <= 8'b0;
            sig_b_reg <= 8'b0;
            valid_reg <= 1'b0;
        end else begin
            sig_a_reg <= sig_a;
            sig_b_reg <= sig_b;
            valid_reg <= valid_in;
        end
    end
    
    // 组合逻辑计算结果直接寄存(重定时)
    // 将原本两级流水线中的后向寄存器移到组合逻辑之前
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            xnor_result <= 8'b0;
            valid_out_reg <= 1'b0;
        end else begin
            xnor_result <= ~(sig_a_reg ^ sig_b_reg);
            valid_out_reg <= valid_reg;
        end
    end
    
    // 输出赋值
    assign q = xnor_result;
    assign valid_out = valid_out_reg;
    
endmodule