//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: BusMask_AND_Top
// Description: Top level module that implements a bus masking operation
// using hierarchical sub-modules for improved design structure
///////////////////////////////////////////////////////////////////////////////
module BusMask_AND_Top #(
    parameter BUS_WIDTH = 16
)(
    input [BUS_WIDTH-1:0] bus_in,
    input [BUS_WIDTH-1:0] mask,
    output [BUS_WIDTH-1:0] masked_bus
);

    // Internal signals for connecting sub-modules
    wire [BUS_WIDTH-1:0] masked_result;
    
    // Instantiate the masking operation module
    BusMask_Operation #(
        .BUS_WIDTH(BUS_WIDTH),
        .OPERATION_TYPE("AND")
    ) mask_operation_inst (
        .data_in(bus_in),
        .mask_value(mask),
        .data_out(masked_result)
    );
    
    // Instantiate the output buffer module
    OutputBuffer #(
        .BUS_WIDTH(BUS_WIDTH)
    ) output_buffer_inst (
        .data_in(masked_result),
        .data_out(masked_bus)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: BusMask_Operation
// Description: Performs the specified masking operation on input data
///////////////////////////////////////////////////////////////////////////////
module BusMask_Operation #(
    parameter BUS_WIDTH = 16,
    parameter OPERATION_TYPE = "AND"  // Can be extended to support other operations
)(
    input [BUS_WIDTH-1:0] data_in,
    input [BUS_WIDTH-1:0] mask_value,
    output reg [BUS_WIDTH-1:0] data_out
);

    // Implement the mask operation based on operation type using if-else structure
    always @(*) begin
        if (OPERATION_TYPE == "AND") begin
            data_out = data_in & mask_value;
        end
        // Other operations can be added here for future extensions
        else begin
            data_out = data_in & mask_value;
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: OutputBuffer
// Description: Buffers the output data for improved timing characteristics
///////////////////////////////////////////////////////////////////////////////
module OutputBuffer #(
    parameter BUS_WIDTH = 16
)(
    input [BUS_WIDTH-1:0] data_in,
    output [BUS_WIDTH-1:0] data_out
);

    // Simple buffer assignment
    // This module can be enhanced for better driving capability or timing
    assign data_out = data_in;

endmodule