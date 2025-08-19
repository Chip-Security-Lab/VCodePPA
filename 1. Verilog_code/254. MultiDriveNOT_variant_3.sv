//SystemVerilog
// Top-level module that instantiates sub-modules
module MultiDriveNOT(
    input [7:0] vector,
    output [7:0] inverse
);
    // Split the 8-bit vector into two 4-bit groups for better fanout control
    wire [3:0] lower_inverse, upper_inverse;
    
    // Instantiate lower bits inverter (bits [3:0])
    BitInverterLow lower_inverter (
        .data_in(vector[3:0]),
        .data_out(lower_inverse)
    );
    
    // Instantiate upper bits inverter (bits [7:4])
    BitInverterHigh upper_inverter (
        .data_in(vector[7:4]),
        .data_out(upper_inverse)
    );
    
    // Combine the outputs
    assign inverse = {upper_inverse, lower_inverse};
endmodule

// Sub-module for inverting lower 4 bits
module BitInverterLow(
    input [3:0] data_in,
    output [3:0] data_out
);
    // Parameterized to allow for future customization
    parameter INVERT_ENABLE = 1'b1;
    
    // Conditional inversion based on parameter
    assign data_out = INVERT_ENABLE ? ~data_in : data_in;
endmodule

// Sub-module for inverting upper 4 bits
module BitInverterHigh(
    input [3:0] data_in,
    output [3:0] data_out
);
    // Using generate for potential future customization
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_inverters
            // Individual bit inversion for better control
            assign data_out[i] = ~data_in[i];
        end
    endgenerate
endmodule