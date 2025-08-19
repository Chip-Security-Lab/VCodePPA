//SystemVerilog
//==============================================================================
// File: and_gate_3.v
// Description: 3-input AND gate with deeper pipelined architecture
// Standard: IEEE 1364-2005 Verilog
//==============================================================================
module and_gate_3 (
    input  wire clk,    // Clock input
    input  wire rst_n,  // Active-low reset
    input  wire a,      // Input A
    input  wire b,      // Input B
    input  wire c,      // Input C
    output reg  y       // Output Y (registered)
);

    // Internal pipeline registers
    reg a_stage1, b_stage1, c_stage1;           // Stage 1 registers
    reg a_stage2, b_stage2, c_stage2;           // Stage 2 registers
    reg a_stage3, b_stage3, c_stage3;           // Stage 3 registers
    reg ab_and_stage4;                          // Stage 4 register - partial result (a & b)
    reg ab_and_stage5;                          // Stage 5 register - pipeline for partial result
    
    // Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
            c_stage1 <= 1'b0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
            c_stage1 <= c;
        end
    end

    // Stage 2: Pipeline buffering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage2 <= 1'b0;
            b_stage2 <= 1'b0;
            c_stage2 <= 1'b0;
        end else begin
            a_stage2 <= a_stage1;
            b_stage2 <= b_stage1;
            c_stage2 <= c_stage1;
        end
    end

    // Stage 3: Pipeline buffering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage3 <= 1'b0;
            b_stage3 <= 1'b0;
            c_stage3 <= 1'b0;
        end else begin
            a_stage3 <= a_stage2;
            b_stage3 <= b_stage2;
            c_stage3 <= c_stage2;
        end
    end

    // Stage 4: First AND operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ab_and_stage4 <= 1'b0;
        end else begin
            ab_and_stage4 <= a_stage3 & b_stage3;
        end
    end

    // Stage 5: Pipeline the partial result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ab_and_stage5 <= 1'b0;
        end else begin
            ab_and_stage5 <= ab_and_stage4;
        end
    end

    // Stage 6: Final AND operation and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;
        end else begin
            y <= ab_and_stage5 & c_stage3;
        end
    end

endmodule