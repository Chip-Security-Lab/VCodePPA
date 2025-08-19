//SystemVerilog
// SystemVerilog
module IVMU_StatusRegs_pipelined #(parameter CH=8) (
    input clk, rst,
    input [CH-1:0] active,
    input i_valid, // Input valid signal
    output [CH-1:0] status,
    output o_valid  // Output valid signal
);

    // Stage 1 registers: Register inputs
    reg [CH-1:0] active_stage1;
    reg valid_stage1;

    always @(posedge clk) begin
        if (rst) begin
            active_stage1 <= {CH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            active_stage1 <= active;
            valid_stage1 <= i_valid;
        end
    end

    // Stage 2 logic and register: Perform update based on stage 1 data
    // The status register is part of this stage's state
    reg [CH-1:0] status_reg_stage2;
    reg valid_stage2; // Output valid signal

    always @(posedge clk) begin
        if (rst) begin
            status_reg_stage2 <= {CH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            // If data from stage 1 is valid, perform the update
            if (valid_stage1) begin
                status_reg_stage2 <= status_reg_stage2 | active_stage1;
            end
            // Propagate validity to the output
            valid_stage2 <= valid_stage1;
        end
    end

    // Output assignments
    assign status = status_reg_stage2;
    assign o_valid = valid_stage2;

endmodule