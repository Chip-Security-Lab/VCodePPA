//SystemVerilog
//IEEE 1364-2005 Verilog标准
module sync_decoder (
    input wire clk,           // 系统时钟
    input wire rst_n,         // 异步低电平复位
    input wire [2:0] address, // 3位地址输入
    output reg [7:0] decode_out // 8位解码输出
);

    // 流水线寄存器 - 第一级：地址缓冲
    reg [2:0] address_stage1;
    
    // 流水线寄存器 - 第二级：解码中间结果
    reg [7:0] decode_stage2;
    
    // 地址缓冲寄存器 - 减少输入路径负载
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            address_stage1 <= 3'b000;
        else
            address_stage1 <= address;
    end
    
    // 解码逻辑 - 分离组合逻辑到单独阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            decode_stage2 <= 8'b00000000;
        else
            decode_stage2 <= (8'b00000001 << address_stage1);
    end
    
    // 输出寄存器 - 改善时序余量
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            decode_out <= 8'b00000000;
        else
            decode_out <= decode_stage2;
    end

endmodule