//SystemVerilog
module IVMU_StatusRegs_Pipelined #(parameter CH=8) (
    input clk, rst,
    input [CH-1:0] active,
    output reg [CH-1:0] status
);

    // Pipeline register for the active input signal (Stage 1)
    reg [CH-1:0] active_stage1;

    // The 'status' register holds the result of the update logic
    // which is performed in Stage 2 based on the registered input from Stage 1.

    always @(posedge clk) begin
        // Stage 1: Register the input 'active' with reset
        active_stage1 <= rst ? {CH{1'b0}} : active;

        // Stage 2: Perform the status update based on the registered 'active' from Stage 1, with reset.
        // The logic is: if active_stage1[i] is high, set status[i] to 1 and keep it set.
        // This is equivalent to status <= status | active_stage1;
        status <= rst ? {CH{1'b0}} : (status | active_stage1);
    end

endmodule