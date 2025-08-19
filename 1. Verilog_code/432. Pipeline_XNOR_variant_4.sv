//SystemVerilog
module Pipeline_XNOR(
    input clk,
    input [15:0] a, b,
    input valid_in,        // 输入数据有效信号
    output reg ready_in,   // 输入就绪信号
    output reg [15:0] out,
    output reg valid_out,  // 输出数据有效信号
    input ready_out        // 输出接收就绪信号
);
    reg [15:0] nand_ab;
    reg [15:0] or_ab;
    reg valid_stage1, valid_stage2;
    
    // 输入就绪逻辑
    always @(posedge clk) begin
        ready_in <= ready_out || !valid_out;
    end
    
    // 第一级流水线
    always @(posedge clk) begin
        if (valid_in && ready_in) begin
            // 使用布尔代数优化: ~(a ^ b) = (a & b) | (~a & ~b)
            // 可以进一步优化为: ~((a | b) & (~a | ~b))
            nand_ab <= ~((a | b) & (~a | ~b));
            valid_stage1 <= 1'b1;
        end else if (valid_stage1 && valid_stage2 && ready_out) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 第二级流水线
    always @(posedge clk) begin
        if (valid_stage1 && (!valid_stage2 || ready_out)) begin
            or_ab <= (nand_ab & nand_ab) | (~nand_ab & ~nand_ab); // 保持等效操作
            valid_stage2 <= 1'b1;
        end else if (valid_stage2 && ready_out) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 输出级流水线
    always @(posedge clk) begin
        if (valid_stage2 && ready_out) begin
            out <= or_ab;
            valid_out <= 1'b1;
        end else if (valid_out && ready_out) begin
            valid_out <= 1'b0;
        end
    end
endmodule