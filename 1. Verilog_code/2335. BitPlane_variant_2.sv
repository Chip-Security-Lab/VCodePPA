//SystemVerilog
module BitPlane #(
    parameter W = 8
)(
    input wire clk,                // 添加时钟信号用于流水线
    input wire rst_n,              // 添加复位信号
    input wire [W-1:0] din,        // 输入数据
    output reg [W/2-1:0] dout      // 输出数据（寄存器化）
);

    // 内部信号定义
    reg [W-1:W/2] upper_bits_r;    // 上半部分位的寄存器
    reg [W/2-1:0] lower_bits_r;    // 下半部分位的寄存器
    
    // 第一级流水线：分离数据位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            upper_bits_r <= {(W/2){1'b0}};
            lower_bits_r <= {(W/2){1'b0}};
        end else begin
            upper_bits_r <= din[W-1:W/2];    // 捕获上半部分位
            lower_bits_r <= din[W/2-1:0];    // 捕获下半部分位
        end
    end
    
    // 第二级流水线：数据合并输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {(W/2){1'b0}};
        end else begin
            dout <= upper_bits_r ^ lower_bits_r;  // 位异或操作以展示数据处理
        end
    end

endmodule