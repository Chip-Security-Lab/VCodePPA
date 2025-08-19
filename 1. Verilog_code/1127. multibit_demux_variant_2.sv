//SystemVerilog
module multibit_demux #(
    parameter DATA_WIDTH = 4,             // Width of data bus
    parameter OUT_COUNT = 4               // Number of outputs
) (
    input wire [DATA_WIDTH-1:0] data_in,  // Input data bus
    input wire [1:0] select,              // Selection input
    output reg [DATA_WIDTH*OUT_COUNT-1:0] demux_out // Combined outputs
);
    // Optimize the implementation by using a shift operation based on select value
    // This reduces the code size and potentially improves synthesis results
    integer i;
    
    always @(*) begin
        // Initialize all outputs to zero
        demux_out = {(DATA_WIDTH*OUT_COUNT){1'b0}};
        
        // Place the input data at the correct position using a shift operation
        // This calculates the bit position: select * DATA_WIDTH
        demux_out = data_in << (select * DATA_WIDTH);
    end
endmodule