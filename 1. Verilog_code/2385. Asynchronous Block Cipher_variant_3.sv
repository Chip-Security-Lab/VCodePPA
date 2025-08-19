//SystemVerilog - IEEE 1364-2005
module async_block_cipher #(
    parameter BLOCK_SIZE = 16
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   valid_in,
    input  wire [BLOCK_SIZE-1:0]  plaintext,
    input  wire [BLOCK_SIZE-1:0]  key,
    output wire                   valid_out,
    output wire [BLOCK_SIZE-1:0]  ciphertext,
    output wire                   ready_in
);

    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Stage 1: Key mixing pipeline registers
    reg  [BLOCK_SIZE-1:0] plaintext_stage1;
    reg  [BLOCK_SIZE-1:0] key_stage1;
    wire [BLOCK_SIZE-1:0] key_mix_data;
    
    // Stage 2: Intermediate pipeline registers
    reg  [BLOCK_SIZE-1:0] intermediate_stage2;
    wire [BLOCK_SIZE-1:0] substitution_data;
    
    // Stage 3: Final encryption stage registers
    reg  [BLOCK_SIZE-1:0] ciphertext_stage3;
    wire [BLOCK_SIZE-1:0] permutation_data;
    
    // Always ready to accept new data in this implementation
    assign ready_in = 1'b1;
    
    // Stage 1: Input registration and control signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            plaintext_stage1 <= {BLOCK_SIZE{1'b0}};
            key_stage1 <= {BLOCK_SIZE{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            plaintext_stage1 <= plaintext;
            key_stage1 <= key;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 1: Key mixing datapath
    assign key_mix_data = plaintext_stage1 ^ key_stage1;
    
    // Stage 2: Pipeline registers after key mixing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            intermediate_stage2 <= {BLOCK_SIZE{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            intermediate_stage2 <= key_mix_data;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 2: Substitution datapath with optimized non-linear operation
    genvar i;
    generate
        for (i = 0; i < BLOCK_SIZE/4; i = i + 1) begin : sub_blocks
            // Enhanced substitution logic
            wire [3:0] current_nibble = intermediate_stage2[i*4+:4];
            wire [3:0] next_nibble = intermediate_stage2[((i+1)%(BLOCK_SIZE/4))*4+:4];
            assign substitution_data[i*4+:4] = current_nibble + next_nibble;
        end
    endgenerate
    
    // Stage 3: Added permutation operation for better diffusion
    generate
        for (i = 0; i < BLOCK_SIZE/2; i = i + 1) begin : perm_blocks
            // Permutation logic swaps bits in a deterministic pattern
            assign permutation_data[i] = substitution_data[BLOCK_SIZE-i-1];
            assign permutation_data[BLOCK_SIZE-i-1] = substitution_data[i];
        end
    endgenerate
    
    // Stage 3: Pipeline register after substitution and permutation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ciphertext_stage3 <= {BLOCK_SIZE{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            ciphertext_stage3 <= permutation_data;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Final output
    assign ciphertext = ciphertext_stage3;
    assign valid_out = valid_stage3;

endmodule