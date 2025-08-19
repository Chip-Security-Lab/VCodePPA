//SystemVerilog
module secded_hamming_gen #(parameter DATA_WIDTH = 64) (
    input wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH+7:0] hamming_out  // 64 data + 8 ECC
);
    wire [7:0] parity;

    // Simplified and optimized parity bit calculations using Boolean algebra
    assign parity[0] = ^data_in[1:0] ^ ^data_in[3:2] ^ ^data_in[5:4] ^ ^data_in[7:6]
                     ^ ^data_in[9:8] ^ ^data_in[11:10] ^ ^data_in[13:12] ^ ^data_in[15:14]
                     ^ ^data_in[17:16] ^ ^data_in[19:18] ^ ^data_in[21:20] ^ ^data_in[23:22]
                     ^ ^data_in[25:24] ^ ^data_in[27:26] ^ ^data_in[29:28] ^ ^data_in[31:30]
                     ^ ^data_in[33:32] ^ ^data_in[35:34] ^ ^data_in[37:36] ^ ^data_in[39:38]
                     ^ ^data_in[41:40] ^ ^data_in[43:42] ^ ^data_in[45:44] ^ ^data_in[47:46]
                     ^ ^data_in[49:48] ^ ^data_in[51:50] ^ ^data_in[53:52] ^ ^data_in[55:54]
                     ^ ^data_in[57:56] ^ ^data_in[59:58] ^ ^data_in[61:60] ^ ^data_in[63:62];

    assign parity[1] = ^data_in[3:0] ^ ^data_in[7:4] ^ ^data_in[11:8] ^ ^data_in[15:12]
                     ^ ^data_in[19:16] ^ ^data_in[23:20] ^ ^data_in[27:24] ^ ^data_in[31:28]
                     ^ ^data_in[35:32] ^ ^data_in[39:36] ^ ^data_in[43:40] ^ ^data_in[47:44]
                     ^ ^data_in[51:48] ^ ^data_in[55:52] ^ ^data_in[59:56] ^ ^data_in[63:60];

    assign parity[2] = ^data_in[7:0] ^ ^data_in[15:8] ^ ^data_in[23:16] ^ ^data_in[31:24]
                     ^ ^data_in[39:32] ^ ^data_in[47:40] ^ ^data_in[55:48] ^ ^data_in[63:56];

    assign parity[3] = ^data_in[15:0] ^ ^data_in[31:16] ^ ^data_in[47:32] ^ ^data_in[63:48];

    assign parity[4] = ^data_in[31:0] ^ ^data_in[63:32];

    assign parity[5] = ^data_in[63:32];

    assign parity[6] = ^data_in[62:0];

    assign parity[7] = ^{data_in, parity[6:0]};

    assign hamming_out = {parity, data_in};
endmodule