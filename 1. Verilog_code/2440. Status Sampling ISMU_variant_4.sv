//SystemVerilog
module status_sampling_ismu #(parameter WIDTH = 8)(
    input wire clk,                 // 时钟信号
    input wire rstn,                // 复位信号，低电平有效
    input wire [WIDTH-1:0] int_raw, // 原始中断信号
    input wire sample_en,           // 采样使能信号
    output reg [WIDTH-1:0] int_status, // 中断状态寄存器
    output reg status_valid         // 状态有效标志
);
    // 存储上一周期的中断值
    reg [WIDTH-1:0] int_prev;
    
    // 状态信号和采样逻辑 - 扁平化if-else结构
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // 异步复位，清除所有寄存器
            int_status <= {WIDTH{1'b0}};
            int_prev <= {WIDTH{1'b0}};
            status_valid <= 1'b0;
        end 
        else if (sample_en) begin
            // 当采样使能有效时，更新中断状态和前一个值
            int_prev <= int_raw;
            int_status <= int_raw;
            status_valid <= 1'b1;
        end
        else begin
            // 当采样使能无效时，只更新前一个值
            int_prev <= int_raw;
            status_valid <= 1'b0;
        end
    end
endmodule