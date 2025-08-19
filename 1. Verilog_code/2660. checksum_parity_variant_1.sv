//SystemVerilog
module checksum_parity (
    input [31:0] data,
    input req,
    output reg ack,
    output reg [7:0] checksum
);

    // 使用位域提取替代wire声明
    wire [7:0] data0 = data[7:0];
    wire [7:0] data1 = data[15:8];
    wire [7:0] data2 = data[23:16];
    wire [7:0] data3 = data[31:24];
    
    // 使用组合逻辑计算校验和
    wire [7:0] sum0 = data0 + data1;
    wire [7:0] sum1 = data2 + data3;
    wire [7:0] total_sum = sum0 + sum1;
    
    // 使用异或树计算奇偶校验
    wire parity = ^total_sum;
    
    always @(*) begin
        checksum = total_sum;
        ack = req & parity;
    end

endmodule