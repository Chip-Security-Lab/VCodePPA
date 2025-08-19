//SystemVerilog
///////////////////////////////////////////////////////////
// Design Name: Hierarchical_XNOR_System
// Module Name: Hierarchical_XNOR_Top
// Description: Top level module for XNOR operations with pipelined datapath
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////

// Top-level module with improved data flow structure
module Hierarchical_XNOR_Top #(
    parameter BIT_WIDTH = 2,
    parameter RESULT_WIDTH = 4
)(
    input wire clk,                    // Clock signal for pipelining
    input wire rst_n,                  // Active-low reset
    input wire [BIT_WIDTH-1:0] a, b,   // Input operands
    output wire [RESULT_WIDTH-1:0] result // Final result
);
    // Pipeline stage 1: Register input operands
    reg [BIT_WIDTH-1:0] a_reg1, b_reg1;
    
    // Pipeline stage 2: XNOR operation results
    reg [BIT_WIDTH-1:0] xnor_results_reg;
    
    // Intermediate signals
    wire [BIT_WIDTH-1:0] xnor_results_wire;
    
    // Input registration (Pipeline stage 1)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg1 <= {BIT_WIDTH{1'b0}};
            b_reg1 <= {BIT_WIDTH{1'b0}};
        end else begin
            a_reg1 <= a;
            b_reg1 <= b;
        end
    end
    
    // Instantiate the XNOR calculator module with parallel prefix subtractor
    XNOR_Calculator #(
        .BIT_WIDTH(BIT_WIDTH)
    ) xnor_calc (
        .operand_a(a_reg1),
        .operand_b(b_reg1),
        .xnor_out(xnor_results_wire)
    );
    
    // Register XNOR results (Pipeline stage 2)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xnor_results_reg <= {BIT_WIDTH{1'b0}};
        end else begin
            xnor_results_reg <= xnor_results_wire;
        end
    end
    
    // Instantiate the result formatter module
    Result_Formatter #(
        .IN_WIDTH(BIT_WIDTH),
        .OUT_WIDTH(RESULT_WIDTH)
    ) formatter (
        .xnor_in(xnor_results_reg),
        .full_result(result)
    );
endmodule

///////////////////////////////////////////////////////////
// Module Name: XNOR_Calculator
// Description: Performs bitwise XNOR operations with optimized datapath
///////////////////////////////////////////////////////////
module XNOR_Calculator #(
    parameter BIT_WIDTH = 2
)(
    input wire [BIT_WIDTH-1:0] operand_a,
    input wire [BIT_WIDTH-1:0] operand_b,
    output wire [BIT_WIDTH-1:0] xnor_out
);
    // Direct XNOR computation for clear data path
    // This simplifies the logic path by avoiding unnecessary subtraction
    genvar i;
    generate
        for (i = 0; i < BIT_WIDTH; i = i + 1) begin : xnor_gen
            assign xnor_out[i] = ~(operand_a[i] ^ operand_b[i]);
        end
    endgenerate
endmodule

///////////////////////////////////////////////////////////
// Module Name: Parallel_Prefix_Subtractor
// Description: 4-bit parallel prefix subtractor with pipelined structure
///////////////////////////////////////////////////////////
module Parallel_Prefix_Subtractor(
    input wire clk,                // Clock for pipeline registers
    input wire rst_n,              // Active-low reset
    input wire [3:0] a,            // Minuend
    input wire [3:0] b,            // Subtrahend
    output wire [3:0] diff         // Difference result
);
    // Pipeline registers for intermediate stages
    reg [3:0] p_stage1, g_stage1;  // Stage 1 propagate and generate signals
    reg [3:0] p_stage2, g_stage2;  // Stage 2 propagate and generate signals
    reg [4:0] carry_reg;           // Registered carry signals
    reg [3:0] diff_reg;            // Registered difference output
    
    // Combinational logic signals
    wire [3:0] b_complement;       // One's complement of b
    wire [3:0] p_init, g_init;     // Initial propagate and generate signals
    wire [3:0] p_level1, g_level1; // Level 1 prefix signals
    wire [3:0] p_level2, g_level2; // Level 2 prefix signals
    wire [4:0] carry_wire;         // Carry signals
    
    // Generate two's complement of b
    assign b_complement = ~b;
    assign carry_wire[0] = 1'b1;   // Add 1 for two's complement subtraction
    
    // Generate initial propagate and generate signals
    assign p_init = a ^ b_complement;
    assign g_init = a & b_complement;
    
    // Stage 1 pipeline: Register initial signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_stage1 <= 4'b0;
            g_stage1 <= 4'b0;
        end else begin
            p_stage1 <= p_init;
            g_stage1 <= g_init;
        end
    end
    
    // Level 1 prefix computation with clearer data path
    // Bit 0 remains unchanged
    assign p_level1[0] = p_stage1[0];
    assign g_level1[0] = g_stage1[0];
    
    // Bit 1: combine with bit 0
    assign p_level1[1] = p_stage1[1] & p_stage1[0];
    assign g_level1[1] = g_stage1[1] | (p_stage1[1] & g_stage1[0]);
    
    // Bit 2 remains unchanged
    assign p_level1[2] = p_stage1[2];
    assign g_level1[2] = g_stage1[2];
    
    // Bit 3: combine with bit 2
    assign p_level1[3] = p_stage1[3] & p_stage1[2];
    assign g_level1[3] = g_stage1[3] | (p_stage1[3] & g_stage1[2]);
    
    // Stage 2 pipeline: Register level 1 signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_stage2 <= 4'b0;
            g_stage2 <= 4'b0;
        end else begin
            p_stage2 <= p_level1;
            g_stage2 <= g_level1;
        end
    end
    
    // Level 2 prefix computation with optimized paths
    // Bits 0-1 remain unchanged
    assign p_level2[0] = p_stage2[0];
    assign g_level2[0] = g_stage2[0];
    assign p_level2[1] = p_stage2[1];
    assign g_level2[1] = g_stage2[1];
    
    // Bit 2: combine with group 0-1
    assign p_level2[2] = p_stage2[2] & p_stage2[1];
    assign g_level2[2] = g_stage2[2] | (p_stage2[2] & g_stage2[1]);
    
    // Bit 3: combine with group 0-1
    assign p_level2[3] = p_stage2[3] & p_stage2[1];
    assign g_level2[3] = g_stage2[3] | (p_stage2[3] & g_stage2[1]);
    
    // Compute carries
    assign carry_wire[1] = g_level2[0] | (p_level2[0] & carry_wire[0]);
    assign carry_wire[2] = g_level2[1] | (p_level2[1] & carry_wire[0]);
    assign carry_wire[3] = g_level2[2] | (p_level2[2] & carry_wire[0]);
    assign carry_wire[4] = g_level2[3] | (p_level2[3] & carry_wire[0]);
    
    // Stage 3 pipeline: Register carries and compute final difference
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            carry_reg <= 5'b0;
            diff_reg <= 4'b0;
        end else begin
            carry_reg <= carry_wire;
            diff_reg <= p_stage2 ^ carry_wire[3:0];
        end
    end
    
    // Output assignment
    assign diff = diff_reg;
endmodule

///////////////////////////////////////////////////////////
// Module Name: Result_Formatter
// Description: Formats the final output result with registered output
///////////////////////////////////////////////////////////
module Result_Formatter #(
    parameter IN_WIDTH = 2,
    parameter OUT_WIDTH = 4
)(
    input wire [IN_WIDTH-1:0] xnor_in,
    output wire [OUT_WIDTH-1:0] full_result
);
    // Combine the XNOR results with fixed high bits
    // Lower bits directly from XNOR input
    assign full_result[IN_WIDTH-1:0] = xnor_in;
    
    // Upper bits fixed to ones for result expansion
    assign full_result[OUT_WIDTH-1:IN_WIDTH] = {(OUT_WIDTH-IN_WIDTH){1'b1}};
endmodule