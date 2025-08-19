//SystemVerilog
module galois_lfsr_rng (
    input wire clock,
    input wire reset,
    input wire enable,
    output reg [7:0] rand_data
);
    // Stage 1: Calculate feedback and partial XORs
    reg feedback_stage1;
    reg [7:0] rand_data_stage1;
    reg valid_stage1;

    // Stage 2: Calculate XORs and form next_rand_data
    reg xor1_stage2, xor2_stage2, xor3_stage2;
    reg [7:0] rand_data_stage2;
    reg feedback_stage2;
    reg valid_stage2;

    // Stage 3: Register the next_rand_data to output
    reg [7:0] next_rand_data_stage3;
    reg valid_stage3;

    // Stage 1
    always @(posedge clock) begin
        if (reset) begin
            rand_data_stage1 <= 8'h1;
            feedback_stage1 <= 1'b1;
            valid_stage1 <= 1'b0;
        end else if (enable) begin
            rand_data_stage1 <= rand_data;
            feedback_stage1 <= rand_data[7];
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // Stage 2
    always @(posedge clock) begin
        if (reset) begin
            rand_data_stage2 <= 8'h1;
            feedback_stage2 <= 1'b1;
            xor1_stage2 <= 1'b0;
            xor2_stage2 <= 1'b0;
            xor3_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            rand_data_stage2 <= rand_data_stage1;
            feedback_stage2 <= feedback_stage1;
            xor1_stage2 <= rand_data_stage1[1] ^ feedback_stage1;
            xor2_stage2 <= rand_data_stage1[2] ^ feedback_stage1;
            xor3_stage2 <= rand_data_stage1[4] ^ feedback_stage1;
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end

    // Stage 3
    always @(posedge clock) begin
        if (reset) begin
            next_rand_data_stage3 <= 8'h1;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            next_rand_data_stage3 <= {
                rand_data_stage2[6],            // next[7]
                rand_data_stage2[5],            // next[6]
                xor3_stage2,                    // next[5]
                rand_data_stage2[3],            // next[4]
                xor2_stage2,                    // next[3]
                xor1_stage2,                    // next[2]
                rand_data_stage2[0],            // next[1]
                feedback_stage2                 // next[0]
            };
            valid_stage3 <= 1'b1;
        end else begin
            valid_stage3 <= 1'b0;
        end
    end

    // Output register
    always @(posedge clock) begin
        if (reset)
            rand_data <= 8'h1;
        else if (valid_stage3)
            rand_data <= next_rand_data_stage3;
    end

endmodule