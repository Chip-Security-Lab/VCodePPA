//SystemVerilog
module onehot_to_binary_priority #(parameter OH_WIDTH = 8) (
    input  wire [OH_WIDTH-1:0] onehot_input,
    output wire [$clog2(OH_WIDTH)-1:0] binary_output,
    output wire valid
);
    // 声明常量和内部信号
    localparam BIN_WIDTH = $clog2(OH_WIDTH);
    
    // 有效信号: 至少有一位为1
    assign valid = |onehot_input;
    
    // 使用二维数组实现并行编码 - 实现类似于并行前缀的结构
    // 每一位输出是通过对应位置的1进行或运算决定的
    wire [BIN_WIDTH-1:0] bin_encoding;
    
    // 为每一个输出位生成编码
    generate
        genvar i;
        for (i = 0; i < BIN_WIDTH; i = i + 1) begin : gen_bin_bit
            // 对于每一位，查看所有onehot位中，位置包含该位为1的输入
            wire [OH_WIDTH-1:0] mask;
            
            genvar k;
            for (k = 0; k < OH_WIDTH; k = k + 1) begin : gen_mask
                assign mask[k] = k[i] ? onehot_input[k] : 1'b0;
            end
            
            // 如果任何一个掩码位为1，则输出位为1
            assign bin_encoding[i] = |mask;
        end
    endgenerate
    
    // 连接到输出
    assign binary_output = bin_encoding;
    
endmodule