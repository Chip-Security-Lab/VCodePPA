//SystemVerilog
//IEEE 1364-2005 Verilog
// Top-level module implementing optimized data flow structure
module xor_nand_gate (
    input wire A, B, C,   // Primary inputs
    output wire Y         // Final output
);
    // Internal pipeline registers for improved timing
    reg stage1_a_and_not_b;
    reg stage1_not_a_and_b;
    reg stage2_xor_result;
    reg stage2_not_c;
    reg stage3_final_output;
    
    // Stage 1: Initial logic decomposition
    always @(*) begin
        stage1_a_and_not_b = A & ~B;     // Path 1: A AND (NOT B)
        stage1_not_a_and_b = ~A & B;     // Path 2: (NOT A) AND B
    end
    
    // Stage 2: XOR result computation and C negation
    always @(*) begin
        stage2_xor_result = stage1_a_and_not_b | stage1_not_a_and_b;  // XOR equivalent
        stage2_not_c = ~C;               // Prepare NOT C for final stage
    end
    
    // Stage 3: Final output generation
    always @(*) begin
        stage3_final_output = stage2_xor_result & stage2_not_c;  // (A XOR B) AND (NOT C)
    end
    
    // Output assignment
    assign Y = stage3_final_output;
    
    // Parameters for timing control and optimization
    parameter CRITICAL_PATH_DELAY = 2;   // Estimated critical path delay
    
    // Synthesis directives for optimization
    // synthesis translate_off
    specify
        (A, B, C *> Y) = CRITICAL_PATH_DELAY;
    endspecify
    // synthesis translate_on
endmodule

// Submodule implementations with improved pipelining capability
module xor_module #(
    parameter XOR_DELAY = 0,
    parameter PIPELINE_STAGES = 0        // Configurable pipeline depth
) (
    input wire clk,                      // Clock for optional pipelining
    input wire reset_n,                  // Active low reset
    input wire a, b,                     // Inputs
    output wire y                        // Output
);
    // Internal signals for multi-stage pipeline
    wire stage1_a_not_b, stage1_not_a_b;
    reg [PIPELINE_STAGES:0] pipeline_result;
    
    // First stage: compute partial products
    assign stage1_a_not_b = a & ~b;
    assign stage1_not_a_b = ~a & b;
    
    // Generate appropriate pipeline structure based on parameter
    generate
        if (PIPELINE_STAGES == 0) begin: NO_PIPELINE
            // Direct combinational path
            assign y = stage1_a_not_b | stage1_not_a_b;
        end
        else begin: WITH_PIPELINE
            // Registered pipeline implementation
            always @(posedge clk or negedge reset_n) begin
                if (!reset_n) begin
                    pipeline_result <= {(PIPELINE_STAGES+1){1'b0}};
                end
                else begin
                    pipeline_result[0] <= stage1_a_not_b | stage1_not_a_b;
                    for (int i=1; i<=PIPELINE_STAGES; i=i+1) begin
                        pipeline_result[i] <= pipeline_result[i-1];
                    end
                end
            end
            
            // Output from final pipeline stage
            assign y = pipeline_result[PIPELINE_STAGES];
        end
    endgenerate
endmodule

// Optimized NAND module with pipeline capability
module nand_module #(
    parameter NAND_DELAY = 0,
    parameter USE_PIPELINE = 0           // Pipeline control parameter
) (
    input wire clk,                      // Clock for optional pipelining
    input wire reset_n,                  // Active low reset
    input wire a, b,                     // Inputs
    output wire y                        // Output
);
    // Internal signal for AND result
    wire and_result;
    reg pipeline_reg;
    
    // Compute AND result
    assign and_result = a & b;
    
    // Pipeline structure based on parameter
    generate
        if (USE_PIPELINE == 0) begin: NO_PIPELINE
            // Direct combinational path
            assign y = ~and_result;
        end
        else begin: WITH_PIPELINE
            // Registered pipeline implementation
            always @(posedge clk or negedge reset_n) begin
                if (!reset_n)
                    pipeline_reg <= 1'b1; // NAND output is 1 when reset
                else
                    pipeline_reg <= ~and_result;
            end
            
            // Output from pipeline register
            assign y = pipeline_reg;
        end
    endgenerate
endmodule