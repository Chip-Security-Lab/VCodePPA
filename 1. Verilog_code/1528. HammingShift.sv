module HammingShift #(parameter DATA_BITS=4) (
    input clk, sin,
    output reg [DATA_BITS+2:0] encoded // 4数据位 + 3校验位
);
// 汉明码(7,4)生成逻辑
wire p0 = encoded[1] ^ encoded[2] ^ encoded[3];
wire p1 = encoded[0] ^ encoded[2] ^ encoded[3];
wire p2 = encoded[0] ^ encoded[1] ^ encoded[3];

always @(posedge clk) begin
    encoded <= {encoded[DATA_BITS+1:0], sin};
    encoded[4] <= p0;
    encoded[5] <= p1;
    encoded[6] <= p2;
end
endmodule
