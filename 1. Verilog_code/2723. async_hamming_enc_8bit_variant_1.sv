//SystemVerilog
module async_hamming_enc_8bit(
    input [7:0] din,
    output [11:0] enc_out
);

    // Pipeline stage 1: Data preparation
    reg [7:0] data_stage1;
    reg [3:0] parity_stage1;
    
    // Pipeline stage 2: Parity calculation
    reg [7:0] data_stage2;
    reg [3:0] parity_stage2;
    reg overall_parity_stage2;

    // Stage 1: Initial data and parity preparation
    always @(*) begin
        // Data bit assignment
        data_stage1[0] = din[1];
        data_stage1[1] = din[2];
        data_stage1[2] = din[3];
        data_stage1[3] = din[4];
        data_stage1[4] = din[5];
        data_stage1[5] = din[6];
        data_stage1[6] = din[7];
        data_stage1[7] = 1'b0;

        // Parity bit calculation
        parity_stage1[0] = din[0] ^ din[1] ^ din[3] ^ din[4] ^ din[6];
        parity_stage1[1] = din[0] ^ din[2] ^ din[3] ^ din[5] ^ din[6];
        parity_stage1[2] = din[0];
        parity_stage1[3] = din[1] ^ din[2] ^ din[3] ^ din[7];
    end

    // Stage 2: Final parity calculation and output preparation
    always @(*) begin
        data_stage2 = data_stage1;
        parity_stage2 = parity_stage1;
        overall_parity_stage2 = ^{parity_stage1, data_stage1};
    end

    // Output assignment
    assign enc_out = {overall_parity_stage2, data_stage2, parity_stage2};

endmodule