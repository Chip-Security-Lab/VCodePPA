//SystemVerilog
// IEEE 1364-2005 Verilog
module HammingShift #(parameter DATA_BITS=4) (
    input clk, sin,
    output reg [DATA_BITS+2:0] encoded // 4数据位 + 3校验位
);
    // 移位寄存器实现
    reg [DATA_BITS-1:0] data_shift;
    
    // 校验位信号
    reg p1, p2, p3;
    
    // 处理数据移位操作
    always @(posedge clk) begin
        // 更新移位寄存器 - 优化数据流
        data_shift <= {data_shift[DATA_BITS-2:0], sin};
    end
    
    // 计算校验位
    always @(*) begin
        // 预计算校验位 - 降低关键路径延迟
        p1 = data_shift[1] ^ data_shift[2] ^ sin;
        p2 = data_shift[0] ^ data_shift[2] ^ sin;
        p3 = data_shift[0] ^ data_shift[1] ^ sin;
    end
    
    // 生成编码输出
    always @(posedge clk) begin
        // 并行赋值编码输出 - 减少逻辑层级
        encoded <= {p3, p2, p1, data_shift[DATA_BITS-1:0]};
    end
endmodule