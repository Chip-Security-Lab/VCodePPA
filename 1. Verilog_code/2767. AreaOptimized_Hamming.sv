module AreaOptimized_Hamming(
    input [3:0] din,
    output [6:0] code
);
// 最小化逻辑门实现
assign code[0] = din[0] ^ din[1] ^ din[3];
assign code[1] = din[0] ^ din[2] ^ din[3];
assign code[2] = din[0];
assign code[3] = din[1] ^ din[2] ^ din[3];
assign code[4] = din[1];
assign code[5] = din[2];
assign code[6] = din[3];
endmodule