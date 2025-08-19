//SystemVerilog
// 顶层模块
module AreaOptimized_Hamming(
    input [3:0] din,
    output [6:0] code
);
    // 内部连线
    wire [2:0] parity_bits;
    wire [3:0] data_bits;
    
    // 实例化奇偶校验位生成子模块
    Parity_Generator parity_gen (
        .data(din),
        .parity(parity_bits)
    );
    
    // 实例化数据位传递子模块
    Data_Passthrough data_pass (
        .data_in(din),
        .data_out(data_bits)
    );
    
    // 将奇偶校验位和数据位组合为完整的Hamming码
    Code_Assembler code_asm (
        .parity(parity_bits),
        .data(data_bits),
        .hamming_code(code)
    );
endmodule

// 奇偶校验位生成子模块
module Parity_Generator(
    input [3:0] data,
    output [2:0] parity
);
    // 计算每个奇偶校验位
    assign parity[0] = data[0] ^ data[1] ^ data[3]; // 位置1的奇偶校验 (P1)
    assign parity[1] = data[0] ^ data[2] ^ data[3]; // 位置2的奇偶校验 (P2)
    assign parity[2] = data[1] ^ data[2] ^ data[3]; // 位置4的奇偶校验 (P4)
endmodule

// 数据位传递子模块
module Data_Passthrough(
    input [3:0] data_in,
    output [3:0] data_out
);
    // 直接传递数据位
    assign data_out = data_in;
endmodule

// 最终编码组装子模块
module Code_Assembler(
    input [2:0] parity,
    input [3:0] data,
    output [6:0] hamming_code
);
    // 组装完整的Hamming码
    assign hamming_code[0] = parity[0];  // P1
    assign hamming_code[1] = parity[1];  // P2
    assign hamming_code[2] = data[0];    // D1
    assign hamming_code[3] = parity[2];  // P4
    assign hamming_code[4] = data[1];    // D2
    assign hamming_code[5] = data[2];    // D3
    assign hamming_code[6] = data[3];    // D4
endmodule