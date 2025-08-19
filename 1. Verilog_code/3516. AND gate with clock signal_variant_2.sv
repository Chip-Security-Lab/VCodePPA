//SystemVerilog
module and_gate_clock (
    input wire clk,     // Clock signal
    input wire rst,     // Reset signal
    input wire valid_in,// Input valid signal
    output wire ready_in,// Ready to accept input
    input wire a,       // Input A
    input wire b,       // Input B
    output wire y,      // Output Y
    output wire valid_out,// Output valid signal
    input wire ready_out // Downstream ready signal
);
    // Stage 1 signals
    reg a_stage1, b_stage1;
    reg valid_stage1;
    
    // Stage 2 signals
    reg result_stage2;
    reg valid_stage2;
    
    // Pipeline control signals
    wire stall_pipeline = valid_stage2 && !ready_out;
    assign ready_in = !stall_pipeline;
    
    // Stage 1 logic: Register inputs
    always @(posedge clk) begin
        if (rst) begin
            a_stage1 <= 1'b0;
            b_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else if (!stall_pipeline) begin
            a_stage1 <= a;
            b_stage1 <= b;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2 logic: Compute AND operation and register result
    always @(posedge clk) begin
        if (rst) begin
            result_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (!stall_pipeline) begin
            result_stage2 <= a_stage1 & b_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output assignments
    assign y = result_stage2;
    assign valid_out = valid_stage2;
    
endmodule