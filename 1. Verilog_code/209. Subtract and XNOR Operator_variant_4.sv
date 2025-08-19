//SystemVerilog
module subtract_xnor_operator (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    output reg [7:0] difference,
    output reg [7:0] xnor_result
);

    // 内部流水线寄存器
    reg [7:0] a_reg, b_reg;
    reg [7:0] diff_stage1;
    reg [7:0] xnor_stage1;
    
    // 第一级流水线：寄存输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // 第二级流水线：计算减法和XNOR结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_stage1 <= 8'b0;
            xnor_stage1 <= 8'b0;
        end else begin
            // 使用加法器实现减法，避免减法器延迟
            diff_stage1 <= a_reg + (~b_reg + 1'b1);
            // 使用AND和OR门实现XNOR，减少门延迟
            xnor_stage1 <= (a_reg & b_reg) | (~a_reg & ~b_reg);
        end
    end
    
    // 第三级流水线：输出结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            difference <= 8'b0;
            xnor_result <= 8'b0;
        end else begin
            difference <= diff_stage1;
            xnor_result <= xnor_stage1;
        end
    end
    
endmodule