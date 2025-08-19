//SystemVerilog
// SystemVerilog
module IVMU_AutoClear_Pipelined #(parameter W=8) (
    input clk,
    input rst_n, // Synchronous reset, active low
    input ack,
    input [W-1:0] irq,
    input input_valid, // Explicit input valid signal for the pipeline
    output reg [W-1:0] active_irq,
    output reg output_valid // Explicit output valid signal from the pipeline
);

// Pipeline Stage 1 Registers: Input Registration
reg [W-1:0] irq_s1;
reg ack_s1;
reg valid_s1; // Valid signal for data in stage 1

// Pipeline Stage 2 Registers: Computation and State Update
// active_irq is the state register, updated in this stage.
// valid_s2 tracks the validity of the data processed in this stage.
reg valid_s2;

// Stage 1: Input Registration
always @(posedge clk) begin
    if (!rst_n) begin
        irq_s1 <= 0;
        ack_s1 <= 0;
        valid_s1 <= 0;
    end else begin
        // Register inputs and the input valid signal
        irq_s1 <= irq;
        ack_s1 <= ack;
        valid_s1 <= input_valid; // valid_s1 indicates if the registered inputs are valid
    end
end

// Stage 2: Computation and State Update
// This stage computes the next state based on Stage 1 outputs and the current state.
always @(posedge clk) begin
    if (!rst_n) begin
        active_irq <= 0;
        valid_s2 <= 0; // Reset valid_s2
    end else begin
        // The state update happens if valid data arrived from Stage 1
        if (valid_s1) begin
            active_irq <= ack_s1 ? 0 : active_irq | irq_s1;
        end
        // valid_s2 indicates that Stage 2 *processed* a valid item this cycle.
        // This happens if valid_s1 was high.
        valid_s2 <= valid_s1; // valid_s2 is valid_s1 delayed by one stage
    end
end

// Output Logic: Register valid_s2 to create output_valid
// active_irq is the state register, which is the module's output.
// output_valid indicates when active_irq was updated as a result of a valid input transaction.
// This happens one cycle after valid_s2 is high.
always @(posedge clk) begin
    if (!rst_n) begin
        output_valid <= 0;
    end else begin
        output_valid <= valid_s2; // output_valid is valid_s2 delayed by one stage
    end
end

endmodule