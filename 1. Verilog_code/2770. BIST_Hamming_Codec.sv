module BIST_Hamming_Codec(
    input clk,
    input test_en,
    output reg test_pass
);
    reg [3:0] test_pattern;
    reg [6:0] encoded;
    reg [3:0] decoded;
    
    // 初始化应该移到always块中
    initial begin
        test_pass = 1'b1;
        test_pattern = 4'b0000;
    end
    
    // 实现编码函数
    function [6:0] Hamming7_4_Encoder;
        input [3:0] data;
        begin
            Hamming7_4_Encoder[3:0] = data;
            Hamming7_4_Encoder[4] = data[0] ^ data[1] ^ data[3];
            Hamming7_4_Encoder[5] = data[0] ^ data[2] ^ data[3];
            Hamming7_4_Encoder[6] = data[1] ^ data[2] ^ data[3];
        end
    endfunction
    
    // 实现解码函数
    function [3:0] HammingDecoder;
        input [6:0] code;
        begin
            HammingDecoder = code[3:0]; // 简化实现
        end
    endfunction

    always @(posedge clk) begin
        if(test_en) begin
            encoded <= Hamming7_4_Encoder(test_pattern);
            decoded <= HammingDecoder(encoded);
            if(decoded !== test_pattern) test_pass <= 1'b0;
            test_pattern <= test_pattern + 1;
        end
    end
endmodule