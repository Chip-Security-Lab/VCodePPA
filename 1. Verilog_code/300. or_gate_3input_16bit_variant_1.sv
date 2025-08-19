//SystemVerilog
module or_gate_3input_16bit (
    input wire clk,
    input wire rst_n,
    input wire [15:0] a,
    input wire [15:0] b,
    input wire [15:0] c,
    output reg [15:0] y
);
    // 分块计算进行 OR 操作，减少扇入，降低负载电容
    // 将 16 位分为 4 个 4 位块进行处理
    wire [3:0] ab_or_block0 = a[3:0] | b[3:0];
    wire [3:0] ab_or_block1 = a[7:4] | b[7:4];
    wire [3:0] ab_or_block2 = a[11:8] | b[11:8];
    wire [3:0] ab_or_block3 = a[15:12] | b[15:12];
    
    // 合并块为第一级流水线输入
    wire [15:0] ab_or = {ab_or_block3, ab_or_block2, ab_or_block1, ab_or_block0};
    
    // 流水线寄存器声明
    reg [15:0] ab_or_reg;
    reg [15:0] result_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位所有流水线寄存器
            ab_or_reg <= 16'b0;
            result_reg <= 16'b0;
            y <= 16'b0;
        end else begin
            // 第一级流水线
            ab_or_reg <= ab_or;
            
            // 第二级流水线 - 使用位分块来优化
            result_reg[3:0] <= ab_or_reg[3:0] | c[3:0];
            result_reg[7:4] <= ab_or_reg[7:4] | c[7:4];
            result_reg[11:8] <= ab_or_reg[11:8] | c[11:8];
            result_reg[15:12] <= ab_or_reg[15:12] | c[15:12];
            
            // 输出寄存器
            y <= result_reg;
        end
    end
    
endmodule