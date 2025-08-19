//SystemVerilog
// Pipelined version of IVMU_ErrorFeedback
// 3-stage pipeline based on explicit register stages for timing isolation
module IVMU_ErrorFeedback_pipelined (
    input clk,
    input reset, // Synchronous reset
    input err_irq, // Input error interrupt signal (acts as data and implicit valid)
    output reg [1:0] err_code, // Output error code
    output reg err_valid       // Output valid signal
);

//------------------------------------------------------------------------------
// Stage 1: Input Registration
// Registers the raw input signal and its validity at the pipeline entry.
//------------------------------------------------------------------------------
reg  err_irq_s1;
reg  valid_s1; // Valid signal after Stage 1 registration

always @(posedge clk or posedge reset) begin
    if (reset) begin
        err_irq_s1 <= 1'b0;
        valid_s1   <= 1'b0;
    end else begin
        // Register the input signal
        err_irq_s1 <= err_irq;
        // The input err_irq signal itself indicates validity in this context
        valid_s1   <= err_irq;
    end
end

//------------------------------------------------------------------------------
// Stage 2: Logic and Registration
// Performs the main logic using Stage 1 outputs and registers the results
// for the next stage.
//------------------------------------------------------------------------------
// Stage 2 Combinational Logic (uses registered data from Stage 1)
wire [1:0] err_code_comb_s2;
// Calculate error code based on the registered input from Stage 1
assign err_code_comb_s2 = {err_irq_s1, 1'b0};

// Stage 2 Registers
reg [1:0] err_code_s2;
reg       valid_s2; // Valid signal after Stage 2 registration

always @(posedge clk or posedge reset) begin
    if (reset) begin
        err_code_s2 <= 2'b0;
        valid_s2    <= 1'b0;
    end else begin
        // Register the calculated error code from Stage 2 combinational logic
        err_code_s2 <= err_code_comb_s2;
        // Register the valid signal from Stage 1
        valid_s2    <= valid_s1;
    end
end

//------------------------------------------------------------------------------
// Stage 3: Output Registration
// Registers the results from Stage 2 before driving the module outputs.
// This stage isolates internal pipeline timing from output loading.
//------------------------------------------------------------------------------
// Output registers are declared as module outputs

always @(posedge clk or posedge reset) begin
    if (reset) begin
        err_code  <= 2'b0;
        err_valid <= 1'b0;
    end else begin
        // Register the results from Stage 2
        err_code  <= err_code_s2;
        err_valid <= valid_s2;
    end
end

endmodule