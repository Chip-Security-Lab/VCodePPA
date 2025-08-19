//SystemVerilog
//IEEE 1364-2005 Verilog
module nand2_9 (
    input wire clk,        // 添加时钟信号用于流水线寄存器
    input wire rst_n,      // 添加复位信号
    input wire [3:0] A,    // 4位输入A
    input wire [3:0] B,    // 4位输入B
    output reg [3:0] Y     // 改为寄存器输出以支持流水线
);
    // 内部流水线寄存器
    reg [3:0] A_stage1, B_stage1;    // 第一级流水线寄存器
    reg [3:0] not_A, not_B;          // 存储取反结果的寄存器
    
    // 流水线阶段1：捕获输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_stage1 <= 4'b0000;
            B_stage1 <= 4'b0000;
        end else begin
            A_stage1 <= A;
            B_stage1 <= B;
        end
    end
    
    // 流水线阶段2：计算取反值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            not_A <= 4'b1111;
            not_B <= 4'b1111;
        end else begin
            not_A <= ~A_stage1;
            not_B <= ~B_stage1;
        end
    end
    
    // 流水线阶段3：计算最终输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 4'b1111;
        end else begin
            Y <= not_A | not_B;  // 使用德摩根定律: ~(A & B) = ~A | ~B
        end
    end

endmodule