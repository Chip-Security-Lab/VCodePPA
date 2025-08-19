//SystemVerilog
module crc8_generator #(parameter DATA_W=8) (
    input clk, rst, en,
    input [DATA_W-1:0] data,
    output reg [7:0] crc
);
    // 内部信号，用于跨always块传递数据
    reg crc_feedback;
    reg [7:0] next_crc;
    
    // 检测输入数据和CRC的异或结果
    always @(*) begin
        crc_feedback = crc[7] ^ data[7];
    end
    
    // 计算下一个CRC值
    always @(*) begin
        if (crc_feedback)
            next_crc = (crc << 1) ^ 8'h07;
        else
            next_crc = (crc << 1);
    end
    
    // 更新CRC寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) 
            crc <= 8'hFF;
        else if (en) 
            crc <= next_crc;
    end
endmodule