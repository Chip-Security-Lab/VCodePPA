//SystemVerilog
module nand2_15 (
    input  wire clk,    // Added clock for pipelining
    input  wire rst_n,  // Added reset signal
    input  wire A, B,   // Primary inputs
    output reg  Y       // Changed to registered output
);
    // Pipeline registers for improved timing
    reg stage1_A, stage1_B;
    reg stage2_and_result;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A <= 1'b0;
            stage1_B <= 1'b0;
        end else begin
            stage1_A <= A;
            stage1_B <= B;
        end
    end
    
    // Stage 2: AND operation with registered inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_and_result <= 1'b0;
        end else begin
            stage2_and_result <= stage1_A & stage1_B;
        end
    end
    
    // Stage 3: NOT operation (final stage)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b1; // Default NAND output is 1 when reset
        end else begin
            Y <= ~stage2_and_result;
        end
    end
endmodule