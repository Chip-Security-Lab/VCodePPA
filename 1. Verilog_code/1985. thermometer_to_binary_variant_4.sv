//SystemVerilog
// Top-level module: thermometer_to_binary
module thermometer_to_binary #(
    parameter THERMO_WIDTH = 7
)(
    input  wire [THERMO_WIDTH-1:0] thermo_in,
    output wire [$clog2(THERMO_WIDTH+1)-1:0] binary_out
);

    wire [$clog2(THERMO_WIDTH+1)-1:0] one_count_binary;
    wire [THERMO_WIDTH-1:0] one_count;

    // Submodule: count_ones
    // Counts the number of '1's in the thermometer input
    count_ones #(
        .WIDTH(THERMO_WIDTH)
    ) u_count_ones (
        .data_in(thermo_in),
        .ones_count(one_count)
    );

    // Submodule: ones_to_binary
    // Converts the one-hot count to binary output
    ones_to_binary #(
        .WIDTH(THERMO_WIDTH)
    ) u_ones_to_binary (
        .ones_vector(one_count),
        .binary_out(one_count_binary)
    );

    assign binary_out = one_count_binary;

endmodule

// -----------------------------------------------------------------------------
// Submodule: count_ones
// Function: Counts the number of '1's in the input vector, outputs as one-hot vector
// -----------------------------------------------------------------------------
module count_ones #(
    parameter WIDTH = 7
)(
    input  wire [WIDTH-1:0] data_in,
    output reg  [WIDTH-1:0] ones_count
);
    integer i;

    always @* begin
        ones_count = 0;
        for (i = 0; i < WIDTH; i = i + 1) begin
            ones_count = ones_count + data_in[i];
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: ones_to_binary
// Function: Converts the one-hot count to binary representation
// -----------------------------------------------------------------------------
module ones_to_binary #(
    parameter WIDTH = 7
)(
    input  wire [WIDTH-1:0] ones_vector,
    output reg  [$clog2(WIDTH+1)-1:0] binary_out
);
    integer sum, j;

    always @* begin
        sum = 0;
        for (j = 0; j < WIDTH; j = j + 1) begin
            sum = sum + ones_vector[j];
        end
        binary_out = sum[$clog2(WIDTH+1)-1:0];
    end
endmodule