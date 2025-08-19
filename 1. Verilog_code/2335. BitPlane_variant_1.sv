//SystemVerilog
module BitPlane #(
    parameter W = 8
)(
    input  wire [W-1:0]   din,
    output wire [W/2-1:0] dout
);
    // 内部连接信号
    wire [W/2-1:0] high_bits;
    wire [W/2-1:0] low_bits;
    
    // 子模块实例化
    BitSplitter #(
        .WIDTH(W)
    ) u_bit_splitter (
        .data_in    (din),
        .high_bits  (high_bits),
        .low_bits   (low_bits)
    );
    
    BitProcessor #(
        .WIDTH(W/2)
    ) u_bit_processor (
        .high_bits  (high_bits),
        .low_bits   (low_bits),
        .result     (dout)
    );
    
endmodule

// 负责将输入数据分割为高位和低位
module BitSplitter #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0]     data_in,
    output wire [WIDTH/2-1:0]   high_bits,
    output wire [WIDTH/2-1:0]   low_bits
);
    // 将输入分割为高位和低位部分
    assign high_bits = data_in[WIDTH-1:WIDTH/2];
    assign low_bits = data_in[WIDTH/2-1:0];
endmodule

// 处理高位和低位数据，执行异或操作
module BitProcessor #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] high_bits,
    input  wire [WIDTH-1:0] low_bits,
    output reg  [WIDTH-1:0] result
);
    // 执行数据处理逻辑
    always @(*) begin
        result = high_bits ^ low_bits;
    end
endmodule