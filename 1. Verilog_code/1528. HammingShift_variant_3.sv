//SystemVerilog
// SystemVerilog
// IEEE 1364-2005
module HammingShift #(parameter DATA_BITS=4) (
    input clk, sin,
    output reg [DATA_BITS+2:0] encoded // 4数据位 + 3校验位
);
    // 输入寄存器 - 直接缓存输入信号
    reg sin_buf;
    
    // 中间数据存储
    reg [DATA_BITS-1:0] data_bits; // 存储数据位
    
    // 组合逻辑计算校验位 - 从data_bits直接计算
    wire p0 = data_bits[1] ^ data_bits[2] ^ data_bits[3];
    wire p1 = data_bits[0] ^ data_bits[2] ^ data_bits[3];
    wire p2 = data_bits[0] ^ data_bits[1] ^ data_bits[3];
    
    // 输出缓冲寄存器
    reg [DATA_BITS+2:0] encoded_next;

    always @(posedge clk) begin
        // 输入缓冲 - 将寄存器移到输入端
        sin_buf <= sin;
        
        // 更新数据位移位寄存器
        data_bits <= {data_bits[DATA_BITS-2:0], sin_buf};
        
        // 组装输出数据 - 移位后的数据和计算得到的校验位
        encoded_next[DATA_BITS-1:0] <= {data_bits[DATA_BITS-2:0], sin_buf};
        encoded_next[4] <= p0;
        encoded_next[5] <= p1;
        encoded_next[6] <= p2;
        
        // 最终输出寄存
        encoded <= encoded_next;
    end
endmodule