//SystemVerilog
// Top module orchestrating error feedback logic
// This module registers the error status and code.
module IVMU_ErrorFeedback (
    input clk,          // Clock signal
    input err_irq,      // Input error interrupt signal
    output logic [1:0] err_code,  // Registered error code output
    output logic err_valid    // Registered error valid output
);

    // Merge logic from previous submodules into a single always block
    always @(posedge clk) begin
        // Logic from error_valid_reg
        err_valid <= err_irq;

        // Logic from error_code_reg
        err_code <= {err_irq, 1'b0};
    end

endmodule