//SystemVerilog
module priority_icmu #(parameter INT_WIDTH = 8, CTX_WIDTH = 32) (
    input wire clk, rst_n,
    input wire [INT_WIDTH-1:0] int_req,
    input wire [CTX_WIDTH-1:0] current_ctx,
    output reg [INT_WIDTH-1:0] int_ack,
    output reg [CTX_WIDTH-1:0] saved_ctx,
    output reg [2:0] int_id,
    output reg active
);
    reg [INT_WIDTH-1:0] int_mask;

    // Function to find the index of the highest set bit
    // Note: This function finds the index of the highest set bit (largest index)
    // if multiple bits are set, by iterating from LSB to MSB.
    // This matches the original code's behavior.
    function [2:0] get_priority;
        input [INT_WIDTH-1:0] req;
        integer i;
        begin
            // Default value if no request is active or if all active requests are masked
            // The loop below will overwrite this if a request is found.
            // If no request is found (req & ~int_mask is 0), the default 0 is kept.
            get_priority = 0;
            // Iterate from LSB to MSB to find the highest index of a set bit
            for (i = 0; i < INT_WIDTH; i = i + 1) begin
                if (req[i]) begin
                    // This will store the index of the last '1' encountered (highest index)
                    get_priority = i;
                end
            end
            // int_id is [2:0], so the returned value is truncated to 3 bits if INT_WIDTH > 8
            // This matches the original behavior where the function result is assigned to int_id [2:0].
        end
    endfunction

    // Combinatorial Barrel Shifter for (1 << int_id)
    // Input is '1' at bit 0. Shift amount is int_id (3 bits). Output is INT_WIDTH bits.
    // This structure implements a left shift by int_id using stages of shifts and MUXes.

    wire [INT_WIDTH-1:0] barrel_shifter_input;
    wire [INT_WIDTH-1:0] barrel_shifter_output;

    // The input to the shifter is the constant 1 at bit position 0
    assign barrel_shifter_input = {{(INT_WIDTH-1){1'b0}}, 1'b1};

    // Barrel shifter stages for a 3-bit shift amount (int_id [2:0])
    // Stage 0: Input
    wire [INT_WIDTH-1:0] stage0_out;
    assign stage0_out = barrel_shifter_input;

    // Stage 1: Shift by 2^0 = 1 if int_id[0] is 1
    wire [INT_WIDTH-1:0] stage1_out;
    assign stage1_out = int_id[0] ? (stage0_out << 1) : stage0_out;

    // Stage 2: Shift by 2^1 = 2 if int_id[1] is 1
    wire [INT_WIDTH-1:0] stage2_out;
    assign stage2_out = int_id[1] ? (stage1_out << 2) : stage1_out;

    // Stage 3: Shift by 2^2 = 4 if int_id[2] is 1
    // This is the final stage for a 3-bit shift amount (max shift 7).
    wire [INT_WIDTH-1:0] stage3_out;
    assign stage3_out = int_id[2] ? (stage2_out << 4) : stage2_out;

    // The output of the barrel shifter is the final stage output
    assign barrel_shifter_output = stage3_out;

    // Registered logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_ack <= 0;
            saved_ctx <= 0;
            int_id <= 0;
            active <= 0;
            int_mask <= 0; // Assuming int_mask should also be reset
        end else begin
            if (|int_req & ~active) begin
                // Calculate the priority ID based on unmasked requests
                // This assignment implicitly truncates the result of get_priority to 3 bits
                int_id <= get_priority(int_req & ~int_mask);

                // Save the current context
                saved_ctx <= current_ctx;

                // Generate the acknowledgment mask using the barrel shifter
                // The barrel_shifter_output is combinatorially derived from the registered int_id
                int_ack <= barrel_shifter_output;

                // Set active flag
                active <= 1;
            end
            // Note: The original code does not show how active is cleared or int_mask is used/updated.
            // We only modify the specified shift operation.
        end
    end

endmodule