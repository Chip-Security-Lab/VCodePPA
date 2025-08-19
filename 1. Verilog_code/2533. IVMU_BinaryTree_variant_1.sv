//SystemVerilog
// SystemVerilog
module IVMU_BinaryTree #(parameter W=8) (
    input [W-1:0] req,
    output [2:0] grant
);

    // W is not used in the logic, fixed at 8 bits for req indexing (7, 6, 5).
    // grant is 3 bits as per original.

    wire [2:0] grant_from_stage_5; // Output of stage 5, input to stage 6
    wire [2:0] grant_from_stage_6; // Output of stage 6, input to stage 7

    // Stage for req[5] - lowest priority among the checked bits (5, 6, 7)
    priority_stage #( .THIS_GRANT_VALUE(3'b101) ) stage_5 (
        .req_bit(req[5]),
        .next_grant_in(3'b000), // Default if req[5], req[6], req[7] are all low
        .grant_out(grant_from_stage_5)
    );

    // Stage for req[6] - medium priority
    priority_stage #( .THIS_GRANT_VALUE(3'b110) ) stage_6 (
        .req_bit(req[6]),
        .next_grant_in(grant_from_stage_5), // Default comes from stage 5
        .grant_out(grant_from_stage_6)
    );

    // Stage for req[7] - highest priority
    priority_stage #( .THIS_GRANT_VALUE(3'b111) ) stage_7 (
        .req_bit(req[7]),
        .next_grant_in(grant_from_stage_6), // Default comes from stage 6
        .grant_out(grant) // Final output of the priority chain
    );

endmodule

// Reusable module for a single priority stage
module priority_stage #(
    parameter [2:0] THIS_GRANT_VALUE = 3'b000 // Value to output if req_bit is high
) (
    input req_bit,          // The request bit for this stage
    input [2:0] next_grant_in, // Grant value from the next lower priority stage
    output [2:0] grant_out     // Output grant value
);
    // If the request bit for this stage is high, output this stage's grant value.
    // Otherwise, pass through the grant value from the next lower priority stage.

    reg [2:0] grant_out_reg;

    always @(*) begin
        if (req_bit) begin
            grant_out_reg = THIS_GRANT_VALUE;
        end else begin
            grant_out_reg = next_grant_in;
        end
    end

    assign grant_out = grant_out_reg;

endmodule