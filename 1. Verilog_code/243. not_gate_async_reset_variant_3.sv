//SystemVerilog
module not_gate_pipeline (
    input wire i_A,
    input wire i_clk,
    input wire i_reset,
    input wire i_valid_in,
    output wire o_Y,
    output wire o_valid_out
);

    // Pipeline Stage 1: Input Register
    reg r_A_stage1;
    reg r_valid_stage1;

    // Pipeline Stage 2: NOT operation + Output Register
    reg r_Y_stage2;
    reg r_valid_stage2;

    // Stage 1: Register input and valid signal
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            r_A_stage1 <= 1'b0;
            r_valid_stage1 <= 1'b0;
        end else begin
            r_A_stage1 <= i_A;
            r_valid_stage1 <= i_valid_in;
        end
    end

    // Stage 2: Perform NOT operation and register result and valid signal
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            r_Y_stage2 <= 1'b0;
            r_valid_stage2 <= 1'b0;
        end else begin
            // Simplified boolean expression for NOT operation
            // The original expression ~r_A_stage1 is already the simplest boolean form for a single bit NOT.
            // No further simplification using boolean algebra rules is applicable here to reduce logic.
            // The logic remains the same:
            if (r_valid_stage1) begin
                r_Y_stage2 <= (r_A_stage1 == 1'b0); // Equivalent to ~r_A_stage1 for a single bit
                r_valid_stage2 <= 1'b1;
            end else begin
                r_Y_stage2 <= r_Y_stage2; // Hold previous value
                r_valid_stage2 <= 1'b0;
            end
        end
    end

    // Output Assignments
    assign o_Y = r_Y_stage2;
    assign o_valid_out = r_valid_stage2;

endmodule