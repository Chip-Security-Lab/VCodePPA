//SystemVerilog
module param_mux #(
    parameter DATA_WIDTH = 8,     // Width of data bus
    parameter MUX_DEPTH = 4       // Number of inputs
) (
    input wire [DATA_WIDTH-1:0] data_in [MUX_DEPTH-1:0], // Input array
    input wire [$clog2(MUX_DEPTH)-1:0] select,           // Selection bits
    input wire [DATA_WIDTH-1:0] subtrahend,              // Subtrahend input for subtraction
    input wire subtract_enable,                          // Enable subtraction operation
    output wire [DATA_WIDTH-1:0] data_out                // Selected output
);

    wire [DATA_WIDTH-1:0] selected_data;
    wire [DATA_WIDTH-1:0] subtrahend_twos_complement;
    wire [DATA_WIDTH:0]   subtraction_sum;
    wire [DATA_WIDTH-1:0] subtraction_result;

    assign selected_data = data_in[select];
    assign subtrahend_twos_complement = (~subtrahend) + 8'd1;
    assign subtraction_sum = {1'b0, selected_data} + {1'b0, subtrahend_twos_complement};
    assign subtraction_result = subtraction_sum[DATA_WIDTH-1:0];

    assign data_out = subtract_enable ? subtraction_result : selected_data;

endmodule