module param_demux #(
    parameter OUTPUT_COUNT = 8,         // Number of output lines
    parameter ADDR_WIDTH = 3            // Address width (log2 of outputs)
) (
    input wire data_input,              // Single data input
    input wire [ADDR_WIDTH-1:0] addr,   // Address selection
    output wire [OUTPUT_COUNT-1:0] out  // Multiple outputs
);
    // Generate one-hot output from binary address
    assign out = data_input ? (1 << addr) : {OUTPUT_COUNT{1'b0}};
endmodule