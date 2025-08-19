//SystemVerilog
//=============================================================================
// File: and_gate_top.v
// Description: Hierarchical AND gate implementation with parameterization
// Standard: IEEE 1364-2005
//=============================================================================

module and_gate_top #(
    parameter WIDTH = 8        // Configurable bit width
)(
    input  wire [WIDTH-1:0] a, // Multi-bit input A
    input  wire [WIDTH-1:0] b, // Multi-bit input B
    output wire [WIDTH-1:0] y  // Multi-bit output Y
);
    // Calculate how many nibbles needed
    localparam NIBBLE_COUNT = (WIDTH + 3) / 4;
    
    // Generate multiple nibble modules
    genvar n;
    generate
        for (n = 0; n < NIBBLE_COUNT; n = n + 1) begin : nibble_units
            // Calculate the actual width for this nibble (handles non-multiples of 4)
            localparam NIBBLE_WIDTH = (n == NIBBLE_COUNT-1 && WIDTH % 4 != 0) ? 
                                      (WIDTH % 4) : 4;
            
            and_gate_nibble #(
                .NIBBLE_WIDTH(NIBBLE_WIDTH)
            ) nibble_inst (
                .a_nibble(a[n*4 +: NIBBLE_WIDTH]),
                .b_nibble(b[n*4 +: NIBBLE_WIDTH]),
                .y_nibble(y[n*4 +: NIBBLE_WIDTH])
            );
        end
    endgenerate
endmodule

//=============================================================================
// File: and_gate_nibble.v
// Description: Nibble-based AND gate module with configurable width
// Standard: IEEE 1364-2005
//=============================================================================

module and_gate_nibble #(
    parameter NIBBLE_WIDTH = 4  // Default to 4 bits, but can be configured
)(
    input  wire [NIBBLE_WIDTH-1:0] a_nibble,  // Nibble input A
    input  wire [NIBBLE_WIDTH-1:0] b_nibble,  // Nibble input B
    output wire [NIBBLE_WIDTH-1:0] y_nibble   // Nibble output Y
);
    // Implementation using bit-level operations for best timing characteristics
    and_gate_bit_array #(
        .BIT_COUNT(NIBBLE_WIDTH)
    ) bit_array_inst (
        .a_bits(a_nibble),
        .b_bits(b_nibble),
        .y_bits(y_nibble)
    );
endmodule

//=============================================================================
// File: and_gate_bit_array.v
// Description: Configurable bit-width AND operation with optimized timing
// Standard: IEEE 1364-2005
//=============================================================================

module and_gate_bit_array #(
    parameter BIT_COUNT = 4     // Configurable bit width
)(
    input  wire [BIT_COUNT-1:0] a_bits,  // Multi-bit input A
    input  wire [BIT_COUNT-1:0] b_bits,  // Multi-bit input B
    output wire [BIT_COUNT-1:0] y_bits   // Multi-bit output Y
);
    // Direct assignment for improved timing and area
    assign y_bits = a_bits & b_bits;
endmodule

//=============================================================================
// Legacy compatibility modules - maintained for backward compatibility
//=============================================================================

// 8-bit AND gate
module and_gate_8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] y
);
    and_gate_top #(.WIDTH(8)) core_inst (
        .a(a),
        .b(b),
        .y(y)
    );
endmodule

// 4-bit AND gate
module and_gate_4 (
    input  wire [3:0] a_in,
    input  wire [3:0] b_in,
    output wire [3:0] y_out
);
    and_gate_nibble #(.NIBBLE_WIDTH(4)) nibble_inst (
        .a_nibble(a_in),
        .b_nibble(b_in),
        .y_nibble(y_out)
    );
endmodule

// 1-bit AND gate
module and_gate_1 (
    input  wire a_bit,
    input  wire b_bit,
    output wire y_bit
);
    assign y_bit = a_bit & b_bit;
endmodule