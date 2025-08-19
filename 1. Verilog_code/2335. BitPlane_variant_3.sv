//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: BitPlane_Top.v
// Description: Top level module for BitPlane system
// Author: Claude
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module BitPlane_Top #(
    parameter W = 8
) (
    input [W-1:0] din,
    output [W/2-1:0] dout
);

    // Internal signals
    wire [W/2-1:0] upper_bits;
    wire [W/2-1:0] lower_bits;

    // Instantiate bit extraction modules
    BitExtractor #(
        .DATA_WIDTH(W),
        .EXTRACT_MSB(1)
    ) upper_extractor (
        .data_in(din),
        .data_out(upper_bits)
    );

    BitExtractor #(
        .DATA_WIDTH(W),
        .EXTRACT_MSB(0)
    ) lower_extractor (
        .data_in(din),
        .data_out(lower_bits)
    );

    // Instantiate bit combiner module
    BitCombiner #(
        .HALF_WIDTH(W/2)
    ) bit_combiner (
        .upper_half(upper_bits),
        .lower_half(lower_bits),
        .combined_out(dout)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: BitExtractor.v
// Description: Module to extract upper or lower bits from input data
// Author: Claude
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module BitExtractor #(
    parameter DATA_WIDTH = 8,
    parameter EXTRACT_MSB = 1  // 1 for MSB half, 0 for LSB half
) (
    input [DATA_WIDTH-1:0] data_in,
    output [DATA_WIDTH/2-1:0] data_out
);

    // Using conditional operator instead of generate-if structure
    assign data_out = EXTRACT_MSB ? data_in[DATA_WIDTH-1:DATA_WIDTH/2] : 
                                    data_in[DATA_WIDTH/2-1:0];

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: BitCombiner.v
// Description: Module to combine upper and lower bit segments
// Author: Claude
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module BitCombiner #(
    parameter HALF_WIDTH = 4
) (
    input [HALF_WIDTH-1:0] upper_half,
    input [HALF_WIDTH-1:0] lower_half,
    output [HALF_WIDTH-1:0] combined_out
);

    // Implement the bit combination logic
    // In this implementation, we're combining upper and lower halves
    assign combined_out = upper_half | lower_half;

endmodule