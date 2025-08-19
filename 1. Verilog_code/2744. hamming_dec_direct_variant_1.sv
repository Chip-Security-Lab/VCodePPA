//SystemVerilog
module hamming_dec_direct (
    input wire clk,                  // Clock input added for pipelining
    input wire rst_n,                // Reset input added for pipeline registers
    input wire [6:0] code_in,        // Encoded input data
    output wire [3:0] data_out,      // Decoded output data
    output wire error                // Error detection flag
);
    // Pipeline stage 1: Syndrome calculation
    reg [6:0] code_in_r1;            // Registered input
    reg [2:0] syndrome_r1;           // Syndrome register
    wire [2:0] syndrome_comb;        // Combinational syndrome
    
    // Optimized syndrome calculation with balanced logic paths
    assign syndrome_comb[0] = ^{code_in[0], code_in[2], code_in[4], code_in[6]};
    assign syndrome_comb[1] = ^{code_in[1], code_in[2], code_in[5], code_in[6]};
    assign syndrome_comb[2] = ^{code_in[3], code_in[4], code_in[5], code_in[6]};
    
    // Stage 1 registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_in_r1 <= 7'b0;
            syndrome_r1 <= 3'b0;
        end else begin
            code_in_r1 <= code_in;
            syndrome_r1 <= syndrome_comb;
        end
    end
    
    // Pipeline stage 2: Error mask generation
    reg [6:0] code_in_r2;            // Pass-through code register
    reg [2:0] syndrome_r2;           // Pass-through syndrome register
    reg [6:0] error_mask_r2;         // Error mask register
    wire [6:0] error_mask_comb;      // Combinational error mask
    
    // Priority-encoded error mask generation with balanced logic paths
    assign error_mask_comb[6] = (syndrome_comb == 3'b111);
    assign error_mask_comb[5] = (syndrome_comb == 3'b110);
    assign error_mask_comb[4] = (syndrome_comb == 3'b101);
    assign error_mask_comb[3] = (syndrome_comb == 3'b100);
    assign error_mask_comb[2] = (syndrome_comb == 3'b011);
    assign error_mask_comb[1] = (syndrome_comb == 3'b010);
    assign error_mask_comb[0] = (syndrome_comb == 3'b001);
    
    // Stage 2 registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_in_r2 <= 7'b0;
            syndrome_r2 <= 3'b0;
            error_mask_r2 <= 7'b0;
        end else begin
            code_in_r2 <= code_in_r1;
            syndrome_r2 <= syndrome_r1;
            error_mask_r2 <= error_mask_comb;
        end
    end
    
    // Pipeline stage 3: Error correction and data extraction
    reg [3:0] data_out_r3;           // Data output register
    reg error_r3;                    // Error flag register
    wire [6:0] corrected_comb;       // Combinational corrected data
    
    // Simplified error correction with syndrome check gating
    assign corrected_comb = code_in_r2 ^ (|syndrome_r2 ? error_mask_r2 : 7'b0);
    
    // Stage 3 registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_r3 <= 4'b0;
            error_r3 <= 1'b0;
        end else begin
            // Extract data bits in a structured manner
            data_out_r3 <= {corrected_comb[6:4], corrected_comb[2]};
            error_r3 <= |syndrome_r2;
        end
    end
    
    // Output assignment
    assign data_out = data_out_r3;
    assign error = error_r3;
    
endmodule