//SystemVerilog
module sub_perm_network #(parameter BLOCK_SIZE = 16) (
    input wire clock, reset_b, process,
    input wire [BLOCK_SIZE-1:0] block_in, key,
    output reg [BLOCK_SIZE-1:0] block_out,
    output reg done
);
    // Pre-computed sbox values to reduce case statement lookup latency
    // and improve timing on critical path
    wire [3:0] sbox_lut [0:15];
    assign sbox_lut[0] = 4'hC;
    assign sbox_lut[1] = 4'h5;
    assign sbox_lut[2] = 4'h6;
    assign sbox_lut[3] = 4'hB;
    assign sbox_lut[4] = 4'h9;
    assign sbox_lut[5] = 4'h0;
    assign sbox_lut[6] = 4'hA;
    assign sbox_lut[7] = 4'hD;
    assign sbox_lut[8] = 4'h3;
    assign sbox_lut[9] = 4'hE;
    assign sbox_lut[10] = 4'hF;
    assign sbox_lut[11] = 4'h8;
    assign sbox_lut[12] = 4'h4;
    assign sbox_lut[13] = 4'h7;
    assign sbox_lut[14] = 4'h1;
    assign sbox_lut[15] = 4'h2;
    
    // Pre-compute the permutation indices
    wire [5:0] perm_indices [0:3];
    assign perm_indices[0] = 6'd4;  // (0*4+4)%16
    assign perm_indices[1] = 6'd8;  // (1*4+4)%16
    assign perm_indices[2] = 6'd12; // (2*4+4)%16
    assign perm_indices[3] = 6'd0;  // (3*4+4)%16
    
    reg [BLOCK_SIZE-1:0] state;
    reg processing_flag;
    
    // Pre-computed state XOR key to reduce critical path
    wire [BLOCK_SIZE-1:0] mixed_state = block_in ^ key;
    
    // Break down sbox operations for parallel execution
    wire [3:0] sbox_out_0, sbox_out_1, sbox_out_2, sbox_out_3;
    
    // Generate parallel sbox lookups for each nibble
    assign sbox_out_0 = sbox_lut[state[perm_indices[0]+:4]];
    assign sbox_out_1 = sbox_lut[state[perm_indices[1]+:4]];
    assign sbox_out_2 = sbox_lut[state[perm_indices[2]+:4]];
    assign sbox_out_3 = sbox_lut[state[perm_indices[3]+:4]];
    
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            state <= 0;
            done <= 0;
            processing_flag <= 0;
            block_out <= 0;
        end else if (process) begin
            // Round 1: Key mixing
            state <= mixed_state;
            done <= 0;
            processing_flag <= 1;
        end else if (processing_flag && !done) begin
            // Round 2: Substitution and permutation (parallel implementation)
            block_out[0+:4] <= sbox_out_3;
            block_out[4+:4] <= sbox_out_0;
            block_out[8+:4] <= sbox_out_1;
            block_out[12+:4] <= sbox_out_2;
            done <= 1;
            processing_flag <= 0;
        end
    end
endmodule