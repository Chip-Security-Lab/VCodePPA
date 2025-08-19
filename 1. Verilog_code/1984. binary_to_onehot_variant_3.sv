//SystemVerilog
// Top-level module: Hierarchical binary to onehot converter
module binary_to_onehot #(parameter BINARY_WIDTH=3)(
    input  wire [BINARY_WIDTH-1:0] binary_in,
    output wire [(1<<BINARY_WIDTH)-1:0] onehot_out
);

    // Internal wire to hold the shift result
    wire [(1<<BINARY_WIDTH)-1:0] shift_result;

    // Submodule: Performs left shift based onehot encoding
    shift_onehot #(
        .WIDTH(BINARY_WIDTH)
    ) u_shift_onehot (
        .in_value(binary_in),
        .out_onehot(shift_result)
    );

    // Submodule: Output register for onehot code
    onehot_output_reg #(
        .ONEHOT_WIDTH((1<<BINARY_WIDTH))
    ) u_onehot_output_reg (
        .onehot_in(shift_result),
        .onehot_out(onehot_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: shift_onehot
// Description: Performs left shift to generate onehot code from binary input
// -----------------------------------------------------------------------------
module shift_onehot #(parameter WIDTH=3)(
    input  wire [WIDTH-1:0] in_value,
    output wire [(1<<WIDTH)-1:0] out_onehot
);
    assign out_onehot = ({{(1<<WIDTH)-1{1'b0}}, 1'b1}) << in_value;
endmodule

// -----------------------------------------------------------------------------
// Submodule: onehot_output_reg
// Description: Output register for onehot code, can be optimized for PPA
// -----------------------------------------------------------------------------
module onehot_output_reg #(parameter ONEHOT_WIDTH=8)(
    input  wire [ONEHOT_WIDTH-1:0] onehot_in,
    output reg  [ONEHOT_WIDTH-1:0] onehot_out
);
    always @* begin
        onehot_out = onehot_in;
    end
endmodule