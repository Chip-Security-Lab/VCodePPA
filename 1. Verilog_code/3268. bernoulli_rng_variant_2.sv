//SystemVerilog
module bernoulli_rng_pipeline #(
    parameter THRESHOLD = 128 // Probability = THRESHOLD/256
)(
    input  wire clk,
    input  wire rst,
    input  wire start,
    output wire random_bit,
    output wire valid
);

    // Stage 1: LFSR update and Bernoulli random bit calculation combined
    reg  [7:0] lfsr_reg_stage1;
    reg        random_bit_stage1;
    reg        valid_stage1;

    wire [7:0] lfsr_next_stage1;
    assign lfsr_next_stage1 = {lfsr_reg_stage1[6:0], lfsr_reg_stage1[7] ^ lfsr_reg_stage1[5] ^ lfsr_reg_stage1[4] ^ lfsr_reg_stage1[3]};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr_reg_stage1    <= 8'h1;
            random_bit_stage1  <= 1'b0;
            valid_stage1       <= 1'b0;
        end else begin
            if (start) begin
                lfsr_reg_stage1    <= lfsr_reg_stage1;
                random_bit_stage1  <= (lfsr_reg_stage1 < THRESHOLD) ? 1'b1 : 1'b0;
                valid_stage1       <= 1'b1;
            end else if (valid_stage1) begin
                lfsr_reg_stage1    <= lfsr_next_stage1;
                random_bit_stage1  <= (lfsr_next_stage1 < THRESHOLD) ? 1'b1 : 1'b0;
                valid_stage1       <= 1'b1;
            end else begin
                lfsr_reg_stage1    <= lfsr_reg_stage1;
                random_bit_stage1  <= random_bit_stage1;
                valid_stage1       <= 1'b0;
            end
        end
    end

    assign random_bit = random_bit_stage1;
    assign valid      = valid_stage1;

endmodule