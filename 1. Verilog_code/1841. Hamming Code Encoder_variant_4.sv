//SystemVerilog
// 顶层模块
module hamming_encoder (
    input  wire [3:0] data_in,
    output wire [6:0] encoded_out
);
    // 内部连线
    wire [2:0] parity_bits;
    
    // 实例化奇偶校验位计算模块
    parity_generator parity_gen (
        .data_in(data_in),
        .parity_out(parity_bits)
    );
    
    // 实例化编码输出组织模块
    code_organizer code_org (
        .data_in(data_in),
        .parity_in(parity_bits),
        .encoded_out(encoded_out)
    );
endmodule

// 奇偶校验位计算模块
module parity_generator (
    input  wire [3:0] data_in,
    output wire [2:0] parity_out
);
    // p1 = d1 ^ d2 ^ d4
    assign parity_out[0] = data_in[0] ^ data_in[1] ^ data_in[3];
    
    // p2 = d1 ^ d3 ^ d4
    assign parity_out[1] = data_in[0] ^ data_in[2] ^ data_in[3];
    
    // p4 = d2 ^ d3 ^ d4
    assign parity_out[2] = data_in[1] ^ data_in[2] ^ data_in[3];
endmodule

// 编码输出组织模块
module code_organizer (
    input  wire [3:0] data_in,
    input  wire [2:0] parity_in,
    output wire [6:0] encoded_out
);
    // Hamming code organization: p1,p2,d1,p4,d2,d3,d4
    assign encoded_out[0] = parity_in[0];    // p1
    assign encoded_out[1] = parity_in[1];    // p2
    assign encoded_out[2] = data_in[0];      // d1
    assign encoded_out[3] = parity_in[2];    // p4
    assign encoded_out[4] = data_in[1];      // d2
    assign encoded_out[5] = data_in[2];      // d3
    assign encoded_out[6] = data_in[3];      // d4
endmodule