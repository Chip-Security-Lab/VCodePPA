//SystemVerilog
module basic_xnor (
    input  wire clk,       // Clock input (added for pipelining)
    input  wire rst_n,     // Active-low reset (added for pipeline control)
    input  wire in1,       // First data input
    input  wire in2,       // Second data input
    output wire out        // XNOR result output
);

    // Internal pipeline registers
    reg stage1_in1_r, stage1_in2_r;  // Stage 1 input registers
    reg stage2_xor_r;                // Stage 2 intermediate result
    
    // Stage 1: Register inputs for timing isolation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_in1_r <= 1'b0;
            stage1_in2_r <= 1'b0;
        end else begin
            stage1_in1_r <= in1;
            stage1_in2_r <= in2;
        end
    end
    
    // Stage 2: Compute XOR and register the result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_xor_r <= 1'b0;
        end else begin
            // XOR operation in pipeline stage 2
            stage2_xor_r <= stage1_in1_r ^ stage1_in2_r;
        end
    end
    
    // Final stage: Invert the XOR result to produce XNOR
    // Implemented as a continuous assignment for output driving
    assign out = ~stage2_xor_r;
    
endmodule