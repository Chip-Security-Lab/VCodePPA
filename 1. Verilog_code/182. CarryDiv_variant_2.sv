//SystemVerilog
module CarryDiv(
    input wire clk,           // 添加时钟输入以支持流水线
    input wire rst_n,         // 添加复位信号
    input wire [3:0] D,       // 被除数
    input wire [3:0] d,       // 除数
    output reg [3:0] q        // 商
);
    // 第一级流水线：计算补码和
    reg [3:0] D_reg, d_reg;   // 输入寄存器
    reg [3:0] sum_reg;        // 和寄存器
    wire [3:0] sum_wire;      // 和线网
    
    // 第二级流水线：根据和确定商
    reg sum_sign;             // 和符号位寄存
    reg [3:0] q_pre;          // 预商结果
    
    // 组合逻辑：计算补码加法
    assign sum_wire = D_reg + (~d_reg + 1'b1); // 计算 D - d 的补码加法
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有寄存器
            D_reg <= 4'b0;
            d_reg <= 4'b0;
            sum_reg <= 4'b0;
            sum_sign <= 1'b0;
            q_pre <= 4'b0;
            q <= 4'b0;
        end else begin
            // 第一级流水线：输入寄存和和计算
            D_reg <= D;
            d_reg <= d;
            sum_reg <= sum_wire;
            
            // 第二级流水线：保存符号位
            sum_sign <= sum_reg[3];
            
            // 第三级流水线：计算最终商值
            q_pre <= {3'b0, sum_sign} + (sum_sign ? 4'b0 : 4'b1);
            
            // 输出流水线级
            q <= q_pre;
        end
    end
endmodule