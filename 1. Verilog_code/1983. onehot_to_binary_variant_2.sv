//SystemVerilog
// Top-level module: onehot_to_binary
module onehot_to_binary #(
    parameter ONE_HOT_WIDTH = 8
) (
    input  wire [ONE_HOT_WIDTH-1:0] onehot_in,
    output wire [$clog2(ONE_HOT_WIDTH)-1:0] binary_out
);

    localparam BIN_WIDTH = $clog2(ONE_HOT_WIDTH);

    wire [BIN_WIDTH-1:0] binary_casex_opt;
    wire [BIN_WIDTH-1:0] binary_loop_opt;
    wire                 casex_match_opt;

    // Optimized casex-based decoder submodule
    onehot_casex_decoder_opt #(
        .ONE_HOT_WIDTH(ONE_HOT_WIDTH)
    ) u_casex_decoder_opt (
        .onehot_in(onehot_in),
        .binary_out(binary_casex_opt),
        .casex_match(casex_match_opt)
    );

    // Optimized loop-based decoder submodule
    onehot_loop_decoder_opt #(
        .ONE_HOT_WIDTH(ONE_HOT_WIDTH)
    ) u_loop_decoder_opt (
        .onehot_in(onehot_in),
        .binary_out(binary_loop_opt)
    );

    assign binary_out = casex_match_opt ? binary_casex_opt : binary_loop_opt;

endmodule

// -----------------------------------------------------------------------------
// Submodule: onehot_casex_decoder_opt
// Function: Optimized one-hot to binary decoder using direct priority checks
// -----------------------------------------------------------------------------
module onehot_casex_decoder_opt #(
    parameter ONE_HOT_WIDTH = 8
) (
    input  wire [ONE_HOT_WIDTH-1:0] onehot_in,
    output reg  [$clog2(ONE_HOT_WIDTH)-1:0] binary_out,
    output reg  casex_match
);
    localparam BIN_WIDTH = $clog2(ONE_HOT_WIDTH);
    integer idx;
    reg match_found;

    always @* begin
        binary_out  = {BIN_WIDTH{1'b0}};
        casex_match = 1'b0;
        match_found = 1'b0;
        // Efficient priority encoder using a single for loop
        for (idx = ONE_HOT_WIDTH-1; idx >= 0; idx = idx - 1) begin
            if (!match_found && onehot_in[idx] && (onehot_in & ~(1'b1 << idx)) == {ONE_HOT_WIDTH{1'b0}}) begin
                binary_out  = idx[BIN_WIDTH-1:0];
                casex_match = 1'b1;
                match_found = 1'b1;
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: onehot_loop_decoder_opt
// Function: Optimized one-hot to binary decoder using priority encoder logic
// -----------------------------------------------------------------------------
module onehot_loop_decoder_opt #(
    parameter ONE_HOT_WIDTH = 8
) (
    input  wire [ONE_HOT_WIDTH-1:0] onehot_in,
    output reg  [$clog2(ONE_HOT_WIDTH)-1:0] binary_out
);
    localparam BIN_WIDTH = $clog2(ONE_HOT_WIDTH);
    integer idx;
    always @* begin
        binary_out = {BIN_WIDTH{1'b0}};
        // Optimized: priority encoder structure
        for (idx = ONE_HOT_WIDTH-1; idx >= 0; idx = idx - 1) begin
            if (onehot_in[idx])
                binary_out = idx[BIN_WIDTH-1:0];
        end
    end
endmodule