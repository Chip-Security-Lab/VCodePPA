module param_mux #(
    parameter DATA_WIDTH = 8,     // Width of data bus
    parameter MUX_DEPTH = 4       // Number of inputs
) (
    input wire [DATA_WIDTH-1:0] data_in [MUX_DEPTH-1:0], // Input array
    input wire [$clog2(MUX_DEPTH)-1:0] select,           // Selection bits
    output wire [DATA_WIDTH-1:0] data_out                // Selected output
);
    assign data_out = data_in[select];
endmodule