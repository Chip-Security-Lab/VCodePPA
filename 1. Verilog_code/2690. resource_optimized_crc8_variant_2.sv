//SystemVerilog
module resource_optimized_crc8(
    input wire clk,
    input wire rst,
    input wire data_bit,
    input wire bit_valid,
    output wire [7:0] crc
);
    parameter [7:0] POLY = 8'hD5;
    
    // 内部 CRC 寄存器
    reg [7:0] crc_int;
    // 缓冲寄存器，用于降低 crc 信号的扇出负载
    reg [7:0] crc_buf1, crc_buf2;
    
    // 将输出连接到缓冲寄存器
    assign crc = crc_buf2;
    
    // 计算反馈时，使用内部寄存器减少扇出
    wire feedback = crc_int[7] ^ data_bit;
    
    always @(posedge clk) begin
        if (rst) begin
            crc_int <= 8'h00;
            crc_buf1 <= 8'h00;
            crc_buf2 <= 8'h00;
        end else begin
            // 更新 CRC 计算
            if (bit_valid) begin
                if (feedback)
                    crc_int <= {crc_int[6:0], 1'b0} ^ POLY;
                else
                    crc_int <= {crc_int[6:0], 1'b0};
            end
            
            // 缓冲寄存器级联传递，降低扇出负载
            crc_buf1 <= crc_int;
            crc_buf2 <= crc_buf1;
        end
    end
endmodule