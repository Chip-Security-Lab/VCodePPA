//SystemVerilog
module Pipeline_XNOR(
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire [15:0] a, b,
    output wire valid_out,
    output wire [15:0] out
);
    // 合并XOR和NOT运算到一个表达式以减少逻辑层级
    reg [15:0] xnor_result_stage1;
    reg valid_stage1;
    
    // 阶段2寄存器
    reg [15:0] out_stage2;
    reg valid_stage2;
    
    // 第一阶段: 直接计算XNOR
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xnor_result_stage1 <= 16'b0;
            valid_stage1 <= 1'b0;
        end else begin
            xnor_result_stage1 <= ~(a ^ b); // 直接计算XNOR，减少一个中间寄存器的需求
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二阶段: 仅保留寄存器，不做额外运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_stage2 <= 16'b0;
            valid_stage2 <= 1'b0;
        end else begin
            out_stage2 <= xnor_result_stage1; // 直接传递结果，无需额外运算
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出赋值
    assign out = out_stage2;
    assign valid_out = valid_stage2;
    
endmodule