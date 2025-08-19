module Hamming15_11_Decoder_Async (
    input [14:0] encoded_data,  // 15位含错编码
    output [10:0] corrected_data, // 11位纠正后数据
    output [3:0] error_pos       // 错误位置指示
);
wire p1 = encoded_data[0] ^ encoded_data[2] ^ encoded_data[4] ^ encoded_data[6] 
        ^ encoded_data[8] ^ encoded_data[10] ^ encoded_data[12] ^ encoded_data[14];
wire p2 = encoded_data[1] ^ encoded_data[2] ^ encoded_data[5] ^ encoded_data[6] 
        ^ encoded_data[9] ^ encoded_data[10] ^ encoded_data[13] ^ encoded_data[14];
wire p4 = encoded_data[3] ^ encoded_data[4] ^ encoded_data[5] ^ encoded_data[6] 
        ^ encoded_data[11] ^ encoded_data[12] ^ encoded_data[13] ^ encoded_data[14];
wire p8 = encoded_data[7] ^ encoded_data[8] ^ encoded_data[9] ^ encoded_data[10] 
        ^ encoded_data[11] ^ encoded_data[12] ^ encoded_data[13] ^ encoded_data[14];

assign error_pos = {p8, p4, p2, p1};
assign corrected_data = (|error_pos) ? 
    {encoded_data[14:7], encoded_data[6:3], encoded_data[1]} ^ (1 << (15 - error_pos)) :
    {encoded_data[14:7], encoded_data[6:3], encoded_data[1]};
endmodule