//SystemVerilog
module hamming_xor_tree(
    input [31:0] data,
    output [38:0] encoded
);
    // 中间变量用于存储部分计算结果
    reg [31:0] parity_mask [5:0];
    reg [5:0] parity_partial;
    reg [6:0] parity;
    
    // 预计算掩码
    always @(*) begin
        parity_mask[0] = 32'b01010101010101010101010101010101;
        parity_mask[1] = 32'b00110011001100110011001100110011;
        parity_mask[2] = 32'b00001111000011110000111100001111;
        parity_mask[3] = 32'b00000000111111110000000011111111;
        parity_mask[4] = 32'b00000000000000001111111111111111;
        parity_mask[5] = 32'hFFFFFFFF;
    end
    
    // 分步计算奇偶校验位
    always @(*) begin
        // 第一级：计算各个掩码的XOR结果
        for (int i = 0; i < 6; i = i + 1) begin
            parity_partial[i] = ^(data & parity_mask[i]);
        end
        
        // 第二级：计算最终奇偶校验位
        parity[5:0] = parity_partial;
        parity[6] = ^parity_partial;
    end
    
    // 组装编码输出
    assign encoded[6:0] = parity;
    assign encoded[38:7] = data;
endmodule