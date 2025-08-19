//SystemVerilog
// Top-level Booth Encoder module with hierarchical structure

module booth_encoder #(parameter WIDTH = 4) (
    input  wire [WIDTH:0] multiplier_bits,  // 3 adjacent bits
    output wire [1:0]     booth_op,         // Operation: 00=0, 01=+A, 10=-A, 11=+2A
    output wire           neg               // Negate result
);
    // Internal signals for submodule outputs
    wire [1:0] booth_op_internal;
    wire       neg_internal;

    // Booth encoding logic submodule instance
    booth_encode_logic booth_encode_logic_inst (
        .multiplier_bits(multiplier_bits[2:0]),
        .booth_op(booth_op_internal),
        .neg(neg_internal)
    );

    // Output assignments
    assign booth_op = booth_op_internal;
    assign neg      = neg_internal;

endmodule

// -----------------------------------------------------------------------------
// Submodule: booth_encode_logic
// Function: Implements the Booth encoding combinational logic.
// Inputs:
//   - multiplier_bits [2:0]: Three adjacent bits from the multiplier
// Outputs:
//   - booth_op [1:0]: Encoded operation (00=0, 01=+A, 11=+2A)
//   - neg: Indicates if the result should be negated
// -----------------------------------------------------------------------------
module booth_encode_logic (
    input  wire [2:0] multiplier_bits,
    output reg  [1:0] booth_op,
    output reg        neg
);
    always @(*) begin
        case (multiplier_bits)
            3'b000, 3'b111: begin
                booth_op = 2'b00;
                neg      = 1'b0;
            end
            3'b001, 3'b010: begin
                booth_op = 2'b01;
                neg      = 1'b0;
            end
            3'b101, 3'b110: begin
                booth_op = 2'b01;
                neg      = 1'b1;
            end
            3'b011: begin
                booth_op = 2'b11;
                neg      = 1'b0;
            end
            3'b100: begin
                booth_op = 2'b11;
                neg      = 1'b1;
            end
            default: begin
                booth_op = 2'b00;
                neg      = 1'b0;
            end
        endcase
    end
endmodule