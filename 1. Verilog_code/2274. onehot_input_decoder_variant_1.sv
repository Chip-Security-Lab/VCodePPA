//SystemVerilog
module onehot_input_decoder(
    input [7:0] onehot_in,
    output reg [2:0] binary_out,
    output reg valid
);
    // 检查输入是否为one-hot编码 
    always @(*) begin
        valid = (onehot_in == 8'b00000001 || 
                 onehot_in == 8'b00000010 || 
                 onehot_in == 8'b00000100 || 
                 onehot_in == 8'b00001000 || 
                 onehot_in == 8'b00010000 || 
                 onehot_in == 8'b00100000 || 
                 onehot_in == 8'b01000000 || 
                 onehot_in == 8'b10000000);
    end
    
    // 使用条件运算符替代if-else结构进行二进制编码转换
    always @(*) begin
        binary_out = onehot_in[0] ? 3'b000 :
                     onehot_in[1] ? 3'b001 :
                     onehot_in[2] ? 3'b010 :
                     onehot_in[3] ? 3'b011 :
                     onehot_in[4] ? 3'b100 :
                     onehot_in[5] ? 3'b101 :
                     onehot_in[6] ? 3'b110 :
                     onehot_in[7] ? 3'b111 :
                                    3'b000;
    end
endmodule