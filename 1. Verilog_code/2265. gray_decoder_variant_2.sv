//SystemVerilog
module gray_decoder(
    input [3:0] gray_in,
    output [3:0] binary_out
);
    booth_decoder booth_inst(
        .gray_code(gray_in),
        .binary_out(binary_out)
    );
endmodule

module booth_decoder(
    input [3:0] gray_code,
    output reg [3:0] binary_out
);
    reg [4:0] extended_code;
    reg [4:0] partial_sums[0:1];
    
    // 扩展Gray码以便Booth编码处理
    always @(*) begin
        extended_code = {gray_code, 1'b0};
        
        // 生成部分和 - 将条件运算符转换为if-else结构
        if (extended_code[0]) begin
            partial_sums[0] = 5'b11111;
        end else begin
            partial_sums[0] = 5'b00000;
        end
        
        if (extended_code[1]) begin
            if (extended_code[0]) begin
                partial_sums[1] = 5'b00000;
            end else begin
                partial_sums[1] = 5'b00001;
            end
        end else begin
            if (extended_code[0]) begin
                partial_sums[1] = 5'b11111;
            end else begin
                partial_sums[1] = 5'b00000;
            end
        end
        
        // 使用Booth算法的二进制输出计算
        binary_out[3] = gray_code[3];
        binary_out[2] = binary_out[3] ^ gray_code[2];
        binary_out[1] = binary_out[2] ^ gray_code[1];
        binary_out[0] = binary_out[1] ^ gray_code[0];
    end
endmodule