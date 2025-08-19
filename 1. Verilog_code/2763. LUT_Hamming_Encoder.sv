module LUT_Hamming_Encoder(
    input [3:0] data,
    output [6:0] code
);
// 使用ROM存储预计算结果
reg [6:0] ham_rom [0:15];
initial $readmemh("hamming_lut.hex", ham_rom);
assign code = ham_rom[data];
endmodule