//SystemVerilog
// Top-level module for configurable multi-input AND gate
// Hierarchical design with parametrized modules for better reusability
`timescale 1ns / 1ps
`default_nettype none

module and_gate_top #(
    parameter int INPUT_WIDTH = 3,      // Number of inputs to the AND gate
    parameter int GATE_DELAY = 0,       // Gate delay parameter for timing control
    parameter int PIPELINE_STAGES = 1   // Number of pipeline stages (0 for combinational)
)(
    input  wire                  clk,           // Clock input (used only when PIPELINE_STAGES > 0)
    input  wire                  rst_n,         // Reset input (used only when PIPELINE_STAGES > 0)
    input  wire [INPUT_WIDTH-1:0] input_bus,    // Input bus containing all inputs
    output wire                  result         // Final AND result
);

    // Generate appropriate implementation based on parameters
    generate
        if (PIPELINE_STAGES == 0) begin : g_comb
            // Instantiate combinational implementation
            and_gate_comb #(
                .INPUT_WIDTH(INPUT_WIDTH),
                .GATE_DELAY(GATE_DELAY)
            ) and_comb_inst (
                .inputs(input_bus),
                .result(result)
            );
        end
        else begin : g_pipe
            // Instantiate pipelined implementation
            and_gate_pipe #(
                .INPUT_WIDTH(INPUT_WIDTH),
                .GATE_DELAY(GATE_DELAY),
                .PIPELINE_STAGES(PIPELINE_STAGES)
            ) and_pipe_inst (
                .clk(clk),
                .rst_n(rst_n),
                .inputs(input_bus),
                .result(result)
            );
        end
    endgenerate
    
endmodule

// Combinational multi-input AND gate module
module and_gate_comb #(
    parameter int INPUT_WIDTH = 3,    // Number of inputs
    parameter int GATE_DELAY = 0      // Gate delay for timing control
)(
    input  wire [INPUT_WIDTH-1:0] inputs,  // Input bus
    output wire                   result   // Output result
);
    
    // Internal signals
    wire [INPUT_WIDTH:0] stage_results;
    
    // Initialize first stage with 1 (identity element for AND)
    assign stage_results[0] = 1'b1;
    
    // Create a binary tree structure for better timing
    genvar i;
    generate
        for (i = 0; i < INPUT_WIDTH; i = i + 1) begin : gen_and_stages
            and_primitive #(
                .GATE_DELAY(GATE_DELAY)
            ) and_stage (
                .in1(stage_results[i]),
                .in2(inputs[i]),
                .out(stage_results[i+1])
            );
        end
    endgenerate
    
    // Connect the final stage to the output
    assign result = stage_results[INPUT_WIDTH];
    
endmodule

// Pipelined multi-input AND gate module
module and_gate_pipe #(
    parameter int INPUT_WIDTH = 3,       // Number of inputs
    parameter int GATE_DELAY = 0,        // Gate delay parameter
    parameter int PIPELINE_STAGES = 1    // Number of pipeline stages
)(
    input  wire                   clk,     // Clock input
    input  wire                   rst_n,   // Active-low reset
    input  wire [INPUT_WIDTH-1:0] inputs,  // Input bus
    output wire                   result   // Output result
);

    // Calculate number of inputs per stage
    localparam int INPUTS_PER_STAGE = (INPUT_WIDTH + PIPELINE_STAGES - 1) / PIPELINE_STAGES;
    
    // Internal registers for pipeline stages
    reg [PIPELINE_STAGES:0] pipe_results;
    
    // Initialize first stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_results[0] <= 1'b1;  // Initialize with identity element
        end else begin
            pipe_results[0] <= 1'b1;  // Keep identity element
        end
    end
    
    // Generate pipeline stages
    genvar stage, input_idx;
    generate
        for (stage = 0; stage < PIPELINE_STAGES; stage = stage + 1) begin : gen_pipe_stages
            // Combinational logic for each stage
            wire stage_result;
            
            // AND gate array for current pipeline stage
            and_gate_stage #(
                .STAGE_WIDTH(INPUTS_PER_STAGE),
                .GATE_DELAY(GATE_DELAY)
            ) stage_inst (
                .stage_in(pipe_results[stage]),
                .inputs(inputs[
                    stage*INPUTS_PER_STAGE +: 
                    ((stage+1)*INPUTS_PER_STAGE <= INPUT_WIDTH ? 
                      INPUTS_PER_STAGE : 
                      INPUT_WIDTH - stage*INPUTS_PER_STAGE)
                ]),
                .stage_out(stage_result)
            );
            
            // Register stage output
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    pipe_results[stage+1] <= 1'b0;
                end else begin
                    pipe_results[stage+1] <= stage_result;
                end
            end
        end
    endgenerate
    
    // Connect final stage to output
    assign result = pipe_results[PIPELINE_STAGES];
    
endmodule

// AND gate stage for processing a subset of inputs in the pipeline
module and_gate_stage #(
    parameter int STAGE_WIDTH = 1,    // Number of inputs in this stage
    parameter int GATE_DELAY = 0      // Gate delay parameter
)(
    input  wire                    stage_in,   // Input from previous stage
    input  wire [STAGE_WIDTH-1:0]  inputs,     // Inputs for this stage
    output wire                    stage_out   // Stage output
);

    // Internal connections
    wire [STAGE_WIDTH:0] and_chain;
    
    // Initialize the chain with the stage input
    assign and_chain[0] = stage_in;
    
    // Create AND chain for this stage
    genvar i;
    generate
        for (i = 0; i < STAGE_WIDTH; i = i + 1) begin : gen_stage_ands
            and_primitive #(
                .GATE_DELAY(GATE_DELAY)
            ) and_gate (
                .in1(and_chain[i]),
                .in2(inputs[i]),
                .out(and_chain[i+1])
            );
        end
    endgenerate
    
    // Connect the final result to the stage output
    assign stage_out = and_chain[STAGE_WIDTH];
    
endmodule

// Basic 2-input AND primitive with configurable delay
module and_primitive #(
    parameter int GATE_DELAY = 0    // Gate delay for timing control
)(
    input  wire in1,    // First input
    input  wire in2,    // Second input
    output wire out     // Output
);
    // AND operation with configurable delay
    assign #(GATE_DELAY) out = in1 & in2;
endmodule