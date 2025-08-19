//SystemVerilog
module xorshift_rng (
    input wire clk,
    input wire rst_n,
    output reg [31:0] rand_num
);

    // Stage 1: Combine first two low-complexity stages
    reg [31:0] rand_stage1;
    reg [31:0] rand_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rand_stage1 <= 32'h1;
            rand_stage2 <= 32'h0;
            rand_num    <= 32'h0;
        end else begin
            // Stage 1: (seed ^ (seed << 13)) ^ (((seed ^ (seed << 13)) >> 17))
            rand_stage2 <= (rand_stage1 ^ (rand_stage1 << 13)) ^ ((rand_stage1 ^ (rand_stage1 << 13)) >> 17);

            // Stage 2: (stage1 ^ (stage1 << 13) ^ ((stage1 ^ (stage1 << 13)) >> 17)) ^ (((stage1 ^ (stage1 << 13) ^ ((stage1 ^ (stage1 << 13)) >> 17)) << 5))
            rand_num <= rand_stage2 ^ (rand_stage2 << 5);

            // Feedback for next random number generation
            rand_stage1 <= rand_num;
        end
    end

endmodule