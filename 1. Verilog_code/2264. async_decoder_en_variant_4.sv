//SystemVerilog
//IEEE 1364-2005 Verilog
module async_decoder_en(
    input wire clk,           // 时钟信号
    input wire rst_n,         // 异步复位，低电平有效
    input wire [1:0] addr,    // 地址输入
    input wire enable,        // 使能信号
    output reg [3:0] decode_out // 解码输出
);
    // 预解码信号 - 直接从输入到组合逻辑，无需第一级流水线
    wire [3:0] decode_pre;    // 重定时后的预解码结果 
    reg [3:0] decode_patterns [0:3]; // 解码模式查找表
    
    // 初始化解码模式查找表
    initial begin
        decode_patterns[0] = 4'b0001;
        decode_patterns[1] = 4'b0010;
        decode_patterns[2] = 4'b0100;
        decode_patterns[3] = 4'b1000;
    end

    // 组合逻辑：直接从输入计算预解码结果
    assign decode_pre = enable ? decode_patterns[addr] : 4'b0000;
    
    // 单级流水线：将寄存器从输入后移到组合逻辑之后
    // 这样减少了输入到第一级寄存器的延迟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decode_out <= 4'b0000;
        end else begin
            decode_out <= decode_pre;
        end
    end
endmodule