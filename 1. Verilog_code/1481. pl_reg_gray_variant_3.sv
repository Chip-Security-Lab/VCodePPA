//SystemVerilog
module pl_reg_gray #(
    parameter W = 4
)(
    input wire clk,
    input wire en,
    input wire [W-1:0] bin_in,
    output reg [W-1:0] gray_out
);

    // 内部信号定义 - 分割数据路径
    reg [W-1:0] bin_in_reg;
    wire [W-1:0] bin_shifted;
    wire [W-1:0] gray_computed;
    
    // 第一级流水线 - 输入寄存
    always @(posedge clk) begin
        if (en) begin
            bin_in_reg <= bin_in;
        end
    end
    
    // 组合逻辑部分 - 计算格雷码
    assign bin_shifted = bin_in_reg >> 1;
    assign gray_computed = bin_in_reg ^ bin_shifted;
    
    // 第二级流水线 - 输出寄存
    always @(posedge clk) begin
        if (en) begin
            gray_out <= gray_computed;
        end
    end

endmodule