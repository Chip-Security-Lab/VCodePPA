//SystemVerilog
// Top-level module: Hierarchical bin2onecold encoder
module bin2onecold #(
    parameter BIN_WIDTH = 3
)(
    input  wire [BIN_WIDTH-1:0] bin_in,
    output wire [(2**BIN_WIDTH)-1:0] onecold_out
);

    wire [(2**BIN_WIDTH)-1:0] onehot_wire;

    bin2onehot #(
        .BIN_WIDTH(BIN_WIDTH)
    ) u_bin2onehot (
        .bin_in   (bin_in),
        .onehot_out(onehot_wire)
    );

    onehot2onecold #(
        .WIDTH(2**BIN_WIDTH)
    ) u_onehot2onecold (
        .onehot_in (onehot_wire),
        .onecold_out(onecold_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: bin2onehot
// Function: Converts binary input to one-hot encoding
// Optimized for minimal logic and gate count
// -----------------------------------------------------------------------------
module bin2onehot #(
    parameter BIN_WIDTH = 3
)(
    input  wire [BIN_WIDTH-1:0] bin_in,
    output wire [(2**BIN_WIDTH)-1:0] onehot_out
);
    genvar idx;
    generate
        for (idx = 0; idx < (2**BIN_WIDTH); idx = idx + 1) begin : onehot_gen
            assign onehot_out[idx] = &(~(bin_in ^ idx));
        end
    endgenerate
endmodule

// -----------------------------------------------------------------------------
// Submodule: onehot2onecold
// Function: Inverts one-hot code to produce one-cold output
// Optimized using DeMorgan's Law
// -----------------------------------------------------------------------------
module onehot2onecold #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] onehot_in,
    output wire [WIDTH-1:0] onecold_out
);
    assign onecold_out = {WIDTH{1'b1}} ^ onehot_in;
endmodule