//SystemVerilog
// Top Level Module - Manages the overall tri-state NOT functionality
module TriStateNOT(
    input oe,          // Output enable
    input [3:0] in,    // Input data bus
    output [3:0] out   // Output data bus with tri-state capability
);
    // Internal signals
    wire [3:0] inverted_data;
    
    // Sub-module instantiations
    InverterLogic inverter_unit (
        .data_in(in),
        .data_out(inverted_data)
    );
    
    TriStateBuffer tri_state_unit (
        .oe(oe),
        .data_in(inverted_data),
        .data_out(out)
    );
endmodule

// Sub-module for the inverter logic
module InverterLogic(
    input [3:0] data_in,
    output [3:0] data_out
);
    // Implement the NOT operation
    assign data_out = ~data_in;
endmodule

// Sub-module for tri-state buffer control
module TriStateBuffer(
    input oe,
    input [3:0] data_in,
    output [3:0] data_out
);
    // Implement tri-state behavior based on output enable
    assign data_out = oe ? data_in : 4'bzzzz;
endmodule