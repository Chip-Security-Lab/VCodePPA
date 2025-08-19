//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: threshold_reset_gen_top.v
// Author: ASIC/FPGA Optimization Expert
// Description: Pipelined implementation of threshold-based reset generation
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module threshold_reset_gen_top (
    input  wire       clk,
    input  wire       rst_n,        // Added reset signal
    input  wire       valid_in,     // Added valid signal 
    input  wire [7:0] signal_value,
    input  wire [7:0] threshold,
    output wire       reset_out,
    output wire       valid_out     // Added valid output
);

    // Pipeline control signals
    wire valid_stage1, valid_stage2;
    
    // Data signals between pipeline stages
    wire threshold_exceeded_stage1;

    // Instantiate pipelined comparator module
    threshold_comparator u_comparator (
        .clk                   (clk),
        .rst_n                 (rst_n),
        .valid_in              (valid_in),
        .signal_value          (signal_value),
        .threshold             (threshold),
        .threshold_exceeded    (threshold_exceeded_stage1),
        .valid_out             (valid_stage1)
    );

    // Instantiate pipelined reset generator module
    reset_signal_generator u_reset_gen (
        .clk                   (clk),
        .rst_n                 (rst_n),
        .valid_in              (valid_stage1),
        .threshold_exceeded    (threshold_exceeded_stage1),
        .reset_out             (reset_out),
        .valid_out             (valid_out)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// Pipelined threshold comparator module
///////////////////////////////////////////////////////////////////////////////

module threshold_comparator (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       valid_in,
    input  wire [7:0] signal_value,
    input  wire [7:0] threshold,
    output reg        threshold_exceeded,
    output reg        valid_out
);

    // Stage 1 registers
    reg [7:0] signal_value_stage1;
    reg [7:0] threshold_stage1;
    reg       valid_stage1;
    
    // Stage 2 calculation and valid propagation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            signal_value_stage1  <= 8'h0;
            threshold_stage1     <= 8'h0;
            valid_stage1         <= 1'b0;
            threshold_exceeded   <= 1'b0;
            valid_out            <= 1'b0;
        end else begin
            // Stage 1: Register inputs
            signal_value_stage1  <= signal_value;
            threshold_stage1     <= threshold;
            valid_stage1         <= valid_in;
            
            // Stage 2: Perform comparison
            threshold_exceeded   <= (signal_value_stage1 > threshold_stage1);
            valid_out            <= valid_stage1;
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Pipelined reset signal generator module
///////////////////////////////////////////////////////////////////////////////

module reset_signal_generator (
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,
    input  wire threshold_exceeded,
    output reg  reset_out,
    output reg  valid_out
);

    // Internal pipeline registers
    reg threshold_exceeded_stage1;
    reg valid_stage1;

    // Two-stage pipeline for reset generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            threshold_exceeded_stage1 <= 1'b0;
            valid_stage1              <= 1'b0;
            reset_out                 <= 1'b0;
            valid_out                 <= 1'b0;
        end else begin
            // Stage 1: Register inputs
            threshold_exceeded_stage1 <= threshold_exceeded;
            valid_stage1              <= valid_in;
            
            // Stage 2: Generate reset signal
            reset_out                 <= threshold_exceeded_stage1;
            valid_out                 <= valid_stage1;
        end
    end

endmodule