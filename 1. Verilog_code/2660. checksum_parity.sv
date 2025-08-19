module checksum_parity (
    input [31:0] data, // 转换为打包数组 - 4个8位数据
    output reg parity_valid,
    output reg [7:0] checksum
);
    wire [7:0] data0 = data[7:0];
    wire [7:0] data1 = data[15:8];
    wire [7:0] data2 = data[23:16];
    wire [7:0] data3 = data[31:24];
    
    always @(*) begin
        checksum = data0 + data1 + data2 + data3;
        parity_valid = ^checksum;
    end
endmodule