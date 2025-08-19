//SystemVerilog
module bit_ops_ext (
    input wire clk,          // 时钟信号用于流水线寄存器
    input wire rst_n,        // 复位信号
    input wire [3:0] src1,   // 输入数据源1
    input wire [3:0] src2,   // 输入数据源2
    output reg [3:0] concat, // 连接结果输出
    output reg [3:0] reverse // 反转结果输出
);
    // 内部流水线寄存器
    reg [3:0] src1_reg, src2_reg;
    reg [1:0] src1_lower, src2_lower;
    reg [3:0] src1_reversed_pre;
    
    // 所有流水线阶段合并为一个always块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有寄存器
            src1_reg <= 4'b0;
            src2_reg <= 4'b0;
            src1_lower <= 2'b0;
            src2_lower <= 2'b0;
            src1_reversed_pre <= 4'b0;
            concat <= 4'b0;
            reverse <= 4'b0;
        end else begin
            // 第一阶段：输入寄存
            src1_reg <= src1;
            src2_reg <= src2;
            
            // 第二阶段：数据预处理
            src1_lower <= src1_reg[1:0];
            src2_lower <= src2_reg[1:0];
            src1_reversed_pre <= {src1_reg[0], src1_reg[1], src1_reg[2], src1_reg[3]};
            
            // 第三阶段：最终输出计算
            concat <= {src1_lower, src2_lower};
            reverse <= src1_reversed_pre;
        end
    end
    
endmodule