//SystemVerilog
module inline_log_xnor (
    input  wire a,
    input  wire b,
    input  wire clk,
    input  wire rst_n,
    output wire out
);
    // Internal pipeline signals
    wire xnor_result;
    reg  stage2_result;
    reg  pipeline_out_reg;
    
    // Moved the register after the combinational logic (XNOR operation)
    // Compute XNOR result directly from inputs without registering first
    assign xnor_result = ~(a ^ b); // Explicit XNOR computation
    
    // First pipeline stage - register after XNOR operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 1'b0;
        end else begin
            stage2_result <= xnor_result;
        end
    end
    
    // Output stage - register results for improved timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_out_reg <= 1'b0;
        end else begin
            pipeline_out_reg <= stage2_result;
        end
    end
    
    // Final output assignment
    assign out = pipeline_out_reg;
    
endmodule

module optimized_bit_comparator (
    input  wire clk,
    input  wire rst_n,
    input  wire in1,
    input  wire in2,
    output wire equal
);
    // Direct combinational result
    wire xnor_result = ~(in1 ^ in2); // Explicit XNOR computation
    
    // Register the comparison result
    reg equal_result;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            equal_result <= 1'b0;
        end else begin
            equal_result <= xnor_result;
        end
    end
    
    // Output assignment
    assign equal = equal_result;
    
endmodule