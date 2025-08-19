//SystemVerilog
//===================================================================
// Top-level Reset Polarity Configuration Module
//===================================================================
module config_polarity_reset #(
    parameter CHANNELS = 4
)(
    input  wire                 clk,              // System clock
    input  wire                 reset_in,         // Global reset input
    input  wire [CHANNELS-1:0]  polarity_config,  // Configuration bits for each channel
    output wire [CHANNELS-1:0]  reset_out         // Channel-specific reset outputs
);
    // Internal signals for pipelined architecture
    reg                  reset_in_r1;
    reg  [CHANNELS-1:0]  polarity_config_r1;
    wire [CHANNELS-1:0]  reset_pre_stage;
    
    // First pipeline stage - register inputs
    always @(posedge clk) begin
        reset_in_r1 <= reset_in;
        polarity_config_r1 <= polarity_config;
    end
    
    // Reset processing stage
    reset_processing_core #(
        .CHANNELS(CHANNELS)
    ) reset_proc_core (
        .clk(clk),
        .reset_in(reset_in_r1),
        .polarity_config(polarity_config_r1),
        .reset_pre_stage(reset_pre_stage)
    );
    
    // Output stage - final processing and buffering
    reset_output_stage #(
        .CHANNELS(CHANNELS)
    ) reset_output (
        .clk(clk),
        .reset_pre_stage(reset_pre_stage),
        .reset_out(reset_out)
    );
    
endmodule

//===================================================================
// Reset Processing Core
// Processes reset signals according to polarity configuration
//===================================================================
module reset_processing_core #(
    parameter CHANNELS = 4
)(
    input  wire                 clk,
    input  wire                 reset_in,
    input  wire [CHANNELS-1:0]  polarity_config,
    output reg  [CHANNELS-1:0]  reset_pre_stage
);
    // Internal signals to break down combinational paths
    wire [CHANNELS-1:0] polarity_adjusted_resets;
    
    genvar i;
    generate
        for (i = 0; i < CHANNELS; i = i + 1) begin: reset_gen
            // Calculate polarity-adjusted reset value
            assign polarity_adjusted_resets[i] = polarity_config[i] ? reset_in : ~reset_in;
        end
    endgenerate
    
    // Register the adjusted resets to break combinational paths
    always @(posedge clk) begin
        reset_pre_stage <= polarity_adjusted_resets;
    end
    
endmodule

//===================================================================
// Reset Output Stage
// Handles final reset signal conditioning and output
//===================================================================
module reset_output_stage #(
    parameter CHANNELS = 4
)(
    input  wire                 clk,
    input  wire [CHANNELS-1:0]  reset_pre_stage,
    output reg  [CHANNELS-1:0]  reset_out
);
    // Register outputs for better timing closure
    always @(posedge clk) begin
        reset_out <= reset_pre_stage;
    end
    
endmodule