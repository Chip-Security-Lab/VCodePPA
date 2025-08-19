//SystemVerilog
module IIR_LPF #(
    parameter W = 8,           // 数据位宽
    parameter ALPHA = 4        // 滤波系数
)(
    input wire clk,            // 时钟输入
    input wire rst_n,          // 低电平有效复位
    input wire [W-1:0] din,    // 数据输入
    output reg [W-1:0] dout    // 滤波后输出
);
    // 提前计算常量
    localparam ALPHA_COMP = 8'd255 - ALPHA;
    
    // 分解计算步骤，增加流水线阶段
    reg [15:0] din_term;
    reg [15:0] dout_term;
    reg [15:0] sum;
    reg [W-1:0] din_reg;
    reg [W-1:0] dout_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 异步复位
            din_reg <= {W{1'b0}};
            dout_reg <= {W{1'b0}};
            din_term <= 16'd0;
            dout_term <= 16'd0;
            sum <= 16'd0;
            dout <= {W{1'b0}};
        end else begin
            // 寄存输入和输出，减少扇出负载
            din_reg <= din;
            dout_reg <= dout;
            
            // 并行计算两个乘法项
            din_term <= ALPHA * din_reg;
            dout_term <= ALPHA_COMP * dout_reg;
            
            // 计算总和
            sum <= din_term + dout_term;
            
            // 右移结果输出
            dout <= sum[15:8]; // 直接选择高8位，避免移位操作
        end
    end
endmodule