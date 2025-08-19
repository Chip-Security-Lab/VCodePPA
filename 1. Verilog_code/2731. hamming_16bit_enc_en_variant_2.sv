//SystemVerilog
module hamming_16bit_enc_en(
    input clock, enable, clear,
    input [15:0] data_in,
    output reg [20:0] ham_out
);
    // 计算奇偶位的组合逻辑
    wire [4:0] parity_bits;
    
    // 优化奇偶位计算，使用连续的XOR操作而不是单独的XOR
    assign parity_bits[0] = ^{data_in[0], data_in[2], data_in[4], data_in[6], 
                              data_in[8], data_in[10], data_in[12], data_in[14]};
    assign parity_bits[1] = ^{data_in[1], data_in[2], data_in[5], data_in[6], 
                              data_in[9], data_in[10], data_in[13], data_in[14]};
    assign parity_bits[2] = ^{data_in[3], data_in[4], data_in[5], data_in[6], 
                              data_in[11], data_in[12], data_in[13], data_in[14]};
    assign parity_bits[3] = ^{data_in[7], data_in[8], data_in[9], data_in[10], 
                              data_in[11], data_in[12], data_in[13], data_in[14]};
    assign parity_bits[4] = ^data_in;
    
    // 定义汉明码映射 - 将数据位和奇偶位组合为一个向量
    wire [20:0] ham_out_next;
    
    // 奇偶位位置
    assign ham_out_next[0] = parity_bits[0];
    assign ham_out_next[1] = parity_bits[1];
    assign ham_out_next[3] = parity_bits[2];
    assign ham_out_next[7] = parity_bits[3];
    assign ham_out_next[15] = parity_bits[4];
    
    // 数据位位置 - 使用连续赋值以提高清晰度
    assign ham_out_next[2] = data_in[0];
    assign ham_out_next[6:4] = data_in[3:1];
    assign ham_out_next[14:8] = data_in[10:4];
    assign ham_out_next[20:16] = data_in[15:11];
    
    // 时序逻辑 - 减少逻辑级别，提高性能
    always @(posedge clock) begin
        if (clear) begin
            ham_out <= 21'b0;
        end
        else if (enable) begin
            ham_out <= ham_out_next;
        end
    end
endmodule