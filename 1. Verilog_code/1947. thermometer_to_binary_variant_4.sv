//SystemVerilog
// Top-level module: Hierarchical thermometer to binary converter
module thermometer_to_binary #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] thermo_in,
    output wire [$clog2(WIDTH):0] binary_out
);

    wire [$clog2(WIDTH):0] ones_count;

    // Submodule: OnesCounter
    // Counts the number of '1's in the thermometer input
    ones_counter #(
        .WIDTH(WIDTH)
    ) u_ones_counter (
        .in_vector(thermo_in),
        .ones_count(ones_count)
    );

    // Submodule: CountToBinary
    // Passes the count directly; can be extended for further binary encoding if needed
    count_to_binary #(
        .COUNT_WIDTH($clog2(WIDTH)+1)
    ) u_count_to_binary (
        .count_in(ones_count),
        .binary_out(binary_out)
    );

endmodule

//-----------------------------------------------------------------------------
// Submodule: ones_counter
// Function: Counts the number of '1's in the input vector
//-----------------------------------------------------------------------------
module ones_counter #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] in_vector,
    output reg  [$clog2(WIDTH):0] ones_count
);
    integer idx;
    always @(*) begin
        ones_count = 0;
        idx = 0;
        while (idx < WIDTH) begin
            ones_count = ones_count + in_vector[idx];
            idx = idx + 1;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// Submodule: count_to_binary
// Function: Outputs the binary value of the count (pass-through for thermometer code)
//-----------------------------------------------------------------------------
module count_to_binary #(
    parameter COUNT_WIDTH = 4
)(
    input  wire [COUNT_WIDTH-1:0] count_in,
    output wire [COUNT_WIDTH-1:0] binary_out
);
    // Pass-through; can be modified for additional encoding logic if required
    assign binary_out = count_in;
endmodule