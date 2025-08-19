//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File Name: xor_param_optimized.v
// Description: Pipelined parameterized XOR module with optimized data path
///////////////////////////////////////////////////////////////////////////////

module xor_param #(
    parameter WIDTH = 4,
    parameter PIPELINE_STAGES = 2  // Configurable pipeline depth
) (
    input wire                  clk,       // Clock signal
    input wire                  rst_n,     // Active-low reset
    input wire [WIDTH-1:0]      a,         // Input operand A
    input wire [WIDTH-1:0]      b,         // Input operand B
    output wire [WIDTH-1:0]     y          // Output result
);

    // Internal pipeline registers for improved timing
    reg [WIDTH-1:0] a_stage1, b_stage1;
    reg [WIDTH-1:0] a_stage2, b_stage2;
    reg [WIDTH-1:0] result_stage1;
    reg [WIDTH-1:0] result_stage2;
    
    // First pipeline stage - register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= {WIDTH{1'b0}};
            b_stage1 <= {WIDTH{1'b0}};
        end
        else begin
            a_stage1 <= a;
            b_stage1 <= b;
        end
    end
    
    // Second pipeline stage - compute XOR and register intermediate result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage1 <= {WIDTH{1'b0}};
        end
        else begin
            result_stage1 <= a_stage1 ^ b_stage1;
        end
    end
    
    // Generate block for optional pipeline stages
    generate
        if (PIPELINE_STAGES > 1) begin: extra_pipeline
            // Final pipeline stage
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    result_stage2 <= {WIDTH{1'b0}};
                end
                else begin
                    result_stage2 <= result_stage1;
                end
            end
            
            // Output assignment based on pipeline depth
            assign y = result_stage2;
        end
        else begin: minimal_pipeline
            // Output with single pipeline stage
            assign y = result_stage1;
        end
    endgenerate

endmodule