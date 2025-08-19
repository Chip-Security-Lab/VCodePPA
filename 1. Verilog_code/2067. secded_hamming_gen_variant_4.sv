//SystemVerilog
module secded_hamming_gen #(
    parameter DATA_WIDTH = 64
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [DATA_WIDTH-1:0]  data_in,
    output wire [DATA_WIDTH+7:0]  hamming_out  // 64 data + 8 ECC
);

    // Stage 1: Data register stage
    reg [DATA_WIDTH-1:0] data_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_stage1 <= {DATA_WIDTH{1'b0}};
        else
            data_stage1 <= data_in;
    end

    // Stage 2: Parity calculation pipeline
    reg [7:0] parity_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            parity_stage2 <= 8'b0;
        else begin
            parity_stage2[0] <= ^data_stage1[ 0] ^ ^data_stage1[ 2] ^ ^data_stage1[ 4] ^ ^data_stage1[ 6] ^
                                ^data_stage1[ 8] ^ ^data_stage1[10] ^ ^data_stage1[12] ^ ^data_stage1[14] ^
                                ^data_stage1[16] ^ ^data_stage1[18] ^ ^data_stage1[20] ^ ^data_stage1[22] ^
                                ^data_stage1[24] ^ ^data_stage1[26] ^ ^data_stage1[28] ^ ^data_stage1[30] ^
                                ^data_stage1[32] ^ ^data_stage1[34] ^ ^data_stage1[36] ^ ^data_stage1[38] ^
                                ^data_stage1[40] ^ ^data_stage1[42] ^ ^data_stage1[44] ^ ^data_stage1[46] ^
                                ^data_stage1[48] ^ ^data_stage1[50] ^ ^data_stage1[52] ^ ^data_stage1[54] ^
                                ^data_stage1[56] ^ ^data_stage1[58] ^ ^data_stage1[60] ^ ^data_stage1[62];

            parity_stage2[1] <= ^data_stage1[ 1] ^ ^data_stage1[ 3] ^ ^data_stage1[ 5] ^ ^data_stage1[ 7] ^
                                ^data_stage1[ 9] ^ ^data_stage1[11] ^ ^data_stage1[13] ^ ^data_stage1[15] ^
                                ^data_stage1[17] ^ ^data_stage1[19] ^ ^data_stage1[21] ^ ^data_stage1[23] ^
                                ^data_stage1[25] ^ ^data_stage1[27] ^ ^data_stage1[29] ^ ^data_stage1[31] ^
                                ^data_stage1[33] ^ ^data_stage1[35] ^ ^data_stage1[37] ^ ^data_stage1[39] ^
                                ^data_stage1[41] ^ ^data_stage1[43] ^ ^data_stage1[45] ^ ^data_stage1[47] ^
                                ^data_stage1[49] ^ ^data_stage1[51] ^ ^data_stage1[53] ^ ^data_stage1[55] ^
                                ^data_stage1[57] ^ ^data_stage1[59] ^ ^data_stage1[61] ^ ^data_stage1[63];

            parity_stage2[2] <= ^data_stage1[ 0 +: 4] ^ ^data_stage1[ 8 +: 4] ^
                                ^data_stage1[16 +: 4] ^ ^data_stage1[24 +: 4] ^
                                ^data_stage1[32 +: 4] ^ ^data_stage1[40 +: 4] ^
                                ^data_stage1[48 +: 4] ^ ^data_stage1[56 +: 4];

            parity_stage2[3] <= ^data_stage1[ 0 +: 8] ^ ^data_stage1[16 +: 8] ^
                                ^data_stage1[32 +: 8] ^ ^data_stage1[48 +: 8];

            parity_stage2[4] <= ^data_stage1[ 0 +: 16] ^ ^data_stage1[32 +: 16];

            parity_stage2[5] <= ^data_stage1[ 0 +: 32] ^ ^data_stage1[32 +: 32];

            parity_stage2[6] <= ^data_stage1[1 +: 63];

            parity_stage2[7] <= 1'b0; // reserved for overall parity, calculated in next stage
        end
    end

    // Stage 3: Overall parity and output register
    reg [DATA_WIDTH-1:0] data_stage3;
    reg [7:0]            parity_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3   <= {DATA_WIDTH{1'b0}};
            parity_stage3 <= 8'b0;
        end else begin
            data_stage3   <= data_stage1;
            parity_stage3[6:0] <= parity_stage2[6:0];
            parity_stage3[7]   <= ^{data_stage1, parity_stage2[6:0]};
        end
    end

    // Output assignment: [parity(7:0), data(63:0)]
    assign hamming_out = {parity_stage3, data_stage3};

endmodule