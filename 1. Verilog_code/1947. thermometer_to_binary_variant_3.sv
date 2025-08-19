//SystemVerilog
// Top-level module: thermometer_to_binary
// Function: Converts a thermometer code to binary using hierarchical submodules.
module thermometer_to_binary #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] thermo_in,
    output wire [$clog2(WIDTH):0] binary_out
);

    // Internal signal for population count
    wire [$clog2(WIDTH):0] popcount_result;

    // Population Count Submodule Instance
    popcount #(
        .WIDTH(WIDTH)
    ) u_popcount (
        .data_in   (thermo_in),
        .count_out (popcount_result)
    );

    // Binary Output Assignment Submodule Instance
    assign_binary #(
        .BIN_WIDTH($clog2(WIDTH)+1)
    ) u_assign_binary (
        .in_count  (popcount_result),
        .out_bin   (binary_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: popcount
// Function: Counts the number of '1's in the input vector (thermometer code).
// -----------------------------------------------------------------------------
module popcount #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] data_in,
    output reg  [$clog2(WIDTH):0] count_out
);
    integer idx;
    always @(*) begin
        count_out = {($clog2(WIDTH)+1){1'b0}};
        for (idx = 0; idx < WIDTH; idx = idx + 1) begin
            count_out = count_out + data_in[idx];
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: assign_binary
// Function: Passes the population count to the binary output (buffer stage for hierarchy clarity).
// -----------------------------------------------------------------------------
module assign_binary #(
    parameter BIN_WIDTH = 4
)(
    input  wire [BIN_WIDTH-1:0] in_count,
    output wire [BIN_WIDTH-1:0] out_bin
);
    assign out_bin = in_count;
endmodule