//SystemVerilog
//IEEE 1364-2005 SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Top-level module: nand2_15
// Description: Implements a 2-input NAND gate with optimized pipelined structure
///////////////////////////////////////////////////////////////////////////////
module nand2_15 (
    input  wire clk,    // Clock signal for pipelined operation
    input  wire rst_n,  // Active-low reset
    input  wire A, B,   // Input signals
    output wire Y       // Output signal
);
    // Pipeline stage signals
    wire stage1_and_result;
    reg  stage1_valid;
    reg  stage2_not_result;
    
    // Stage 1: AND operation with input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_valid <= 1'b0;
        end else begin
            stage1_valid <= 1'b1;
        end
    end
    
    // Instantiate the enhanced AND operation submodule
    enhanced_and_operation and_op (
        .clk(clk),
        .rst_n(rst_n),
        .in1(A),
        .in2(B),
        .out(stage1_and_result)
    );
    
    // Stage 2: NOT operation with registered output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_not_result <= 1'b1; // Default NAND output is high when reset
        end else if (stage1_valid) begin
            stage2_not_result <= ~stage1_and_result;
        end
    end
    
    // Output assignment
    assign Y = stage2_not_result;
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Submodule: enhanced_and_operation
// Description: Implements the AND logic operation with configurable pipeline
///////////////////////////////////////////////////////////////////////////////
module enhanced_and_operation (
    input  wire clk,
    input  wire rst_n,
    input  wire in1, in2,
    output wire out
);
    // Internal signals for balanced data path
    reg  input_reg1, input_reg2;
    wire and_result_internal;
    reg  and_result_registered;
    
    // Parameter for propagation characteristics
    parameter AND_DELAY = 0;
    parameter PIPELINE_ENABLE = 1; // Control parameter for pipeline stage
    
    // Register inputs to improve timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_reg1 <= 1'b0;
            input_reg2 <= 1'b0;
        end else begin
            input_reg1 <= in1;
            input_reg2 <= in2;
        end
    end
    
    // Implement AND operation
    and #(AND_DELAY) and_gate (and_result_internal, input_reg1, input_reg2);
    
    // Optional pipeline register for AND result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result_registered <= 1'b0;
        end else begin
            and_result_registered <= and_result_internal;
        end
    end
    
    // Output path selection based on pipeline configuration
    assign out = (PIPELINE_ENABLE) ? and_result_registered : and_result_internal;
    
endmodule