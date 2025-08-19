//SystemVerilog
// -----------------------------------------------------------------------
// Top-level Module: Hierarchical Binary to One-hot Decoder (Modularized)
// -----------------------------------------------------------------------
module binary_to_onehot #(
    parameter BINARY_WIDTH = 3
)(
    input  wire [BINARY_WIDTH-1:0] binary_in,
    output wire [2**BINARY_WIDTH-1:0] onehot_out
);

    // Internal signal for one-hot value
    wire [2**BINARY_WIDTH-1:0] onehot_value;

    // Instantiate encoder logic submodule
    binary_to_onehot_encoder #(
        .BINARY_WIDTH(BINARY_WIDTH)
    ) u_encoder (
        .binary_input(binary_in),
        .onehot_encoded(onehot_value)
    );

    // Instantiate output register submodule for PPA improvement
    binary_to_onehot_register #(
        .ONEHOT_WIDTH(2**BINARY_WIDTH)
    ) u_register (
        .onehot_in(onehot_value),
        .onehot_out(onehot_out)
    );

endmodule

// -----------------------------------------------------------------------
// Submodule: Binary to One-hot Encoder
// Function: Performs combinational binary to one-hot encoding
// -----------------------------------------------------------------------
module binary_to_onehot_encoder #(
    parameter BINARY_WIDTH = 3
)(
    input  wire [BINARY_WIDTH-1:0] binary_input,
    output wire [2**BINARY_WIDTH-1:0] onehot_encoded
);
    // Generate one-hot encoding
    assign onehot_encoded = (1'b1 << binary_input);
endmodule

// -----------------------------------------------------------------------
// Submodule: One-hot Output Register
// Function: Registers the one-hot output to improve timing and PPA
// -----------------------------------------------------------------------
module binary_to_onehot_register #(
    parameter ONEHOT_WIDTH = 8
)(
    input  wire [ONEHOT_WIDTH-1:0] onehot_in,
    output wire [ONEHOT_WIDTH-1:0] onehot_out
);
    // Registered output for better performance and area utilization
    reg [ONEHOT_WIDTH-1:0] onehot_reg;

    always @* begin
        onehot_reg = onehot_in;
    end

    assign onehot_out = onehot_reg;
endmodule