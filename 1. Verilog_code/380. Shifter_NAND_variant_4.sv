//SystemVerilog
module Shifter_NAND(
    input [2:0] shift,
    input [7:0] val,
    output [7:0] res
);
    // Internal signals
    wire [7:0] mult_result;
    wire [7:0] shift_weight;
    
    // Convert shift value to multiplication weight
    ShiftToMultiplier shift_converter (
        .shift(shift),
        .mult_weight(shift_weight)
    );
    
    // Use signed multiplication for operation
    SignedMultiplier multiplier (
        .val(val),
        .weight(shift_weight),
        .result(mult_result)
    );
    
    // Final inversion for NAND functionality
    ResultProcessor processor (
        .data_in(mult_result),
        .data_out(res)
    );
    
endmodule

// Submodule to convert shift value to multiplication weight
module ShiftToMultiplier(
    input [2:0] shift,
    output reg [7:0] mult_weight
);
    // Generate optimized multiplication weights
    always @(*) begin
        case (shift)
            3'b000: mult_weight = 8'b11111111; // No shift
            3'b001: mult_weight = 8'b11111110; // Shift 1
            3'b010: mult_weight = 8'b11111100; // Shift 2
            3'b011: mult_weight = 8'b11111000; // Shift 3
            3'b100: mult_weight = 8'b11110000; // Shift 4
            3'b101: mult_weight = 8'b11100000; // Shift 5
            3'b110: mult_weight = 8'b11000000; // Shift 6
            3'b111: mult_weight = 8'b10000000; // Shift 7
            default: mult_weight = 8'b11111111;
        endcase
    end
endmodule

// Optimized signed multiplication implementation
module SignedMultiplier(
    input [7:0] val,
    input [7:0] weight,
    output [7:0] result
);
    // Internal variables for signed multiplication
    wire signed [7:0] signed_val;
    wire signed [7:0] signed_weight;
    wire signed [15:0] mult_full;
    
    // Convert to signed representation
    assign signed_val = val;
    assign signed_weight = weight;
    
    // Perform signed multiplication and take lower 8 bits
    assign mult_full = signed_val * signed_weight;
    assign result = mult_full[7:0];
endmodule

// Process final result to maintain original functionality
module ResultProcessor(
    input [7:0] data_in,
    output [7:0] data_out
);
    // Apply final transformation to match original functionality
    assign data_out = ~data_in;
endmodule