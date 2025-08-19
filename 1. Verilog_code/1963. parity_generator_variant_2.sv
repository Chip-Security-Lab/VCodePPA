//SystemVerilog
// Top-level module: parity_generator
module parity_generator #(
    parameter DATA_WIDTH = 8,
    parameter EVEN_PARITY = 1  // 1 for even parity, 0 for odd parity
)(
    input  [DATA_WIDTH-1:0] data,
    output parity_bit
);

    // Internal signals for adder/subtractor
    wire [DATA_WIDTH-1:0] minuend;
    wire [DATA_WIDTH-1:0] subtrahend;
    wire [DATA_WIDTH:0]   borrow_chain;
    wire [DATA_WIDTH-1:0] difference;

    assign minuend = data;
    assign subtrahend = {DATA_WIDTH{1'b0}};
    assign borrow_chain[0] = 1'b0;

    // Borrow generator and propagator
    wire [DATA_WIDTH-1:0] borrow_generate;
    wire [DATA_WIDTH-1:0] borrow_propagate;

    // Subtractor Logic Submodule
    subtractor_logic #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_subtractor_logic (
        .minuend_in      (minuend),
        .subtrahend_in   (subtrahend),
        .borrow_generate (borrow_generate),
        .borrow_propagate(borrow_propagate)
    );

    // Fast Borrow Chain Submodule
    borrow_chain_logic #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_borrow_chain_logic (
        .borrow_generate (borrow_generate),
        .borrow_propagate(borrow_propagate),
        .borrow_in       (borrow_chain[0]),
        .borrow_chain    (borrow_chain)
    );

    // Difference Calculation Submodule
    diff_calc #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_diff_calc (
        .minuend_in     (minuend),
        .subtrahend_in  (subtrahend),
        .borrow_chain   (borrow_chain),
        .difference_out (difference)
    );

    // Parity Calculation Submodule
    parity_calc #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_parity_calc (
        .difference_in (difference),
        .even_parity   (EVEN_PARITY),
        .parity_bit    (parity_bit)
    );

endmodule

// -----------------------------------------------------------------------------
// Subtractor Logic Submodule
// Computes borrow generate and propagate signals for each bit
// -----------------------------------------------------------------------------
module subtractor_logic #(
    parameter DATA_WIDTH = 8
)(
    input  [DATA_WIDTH-1:0] minuend_in,
    input  [DATA_WIDTH-1:0] subtrahend_in,
    output [DATA_WIDTH-1:0] borrow_generate,
    output [DATA_WIDTH-1:0] borrow_propagate
);
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : gen_borrow_signals
            assign borrow_generate[i]  = (~minuend_in[i]) & subtrahend_in[i];
            assign borrow_propagate[i] = (~minuend_in[i]) | subtrahend_in[i];
        end
    endgenerate
endmodule

// -----------------------------------------------------------------------------
// Fast Borrow Chain Submodule
// Computes the borrow chain for all bits using generate/propagate signals
// -----------------------------------------------------------------------------
module borrow_chain_logic #(
    parameter DATA_WIDTH = 8
)(
    input  [DATA_WIDTH-1:0] borrow_generate,
    input  [DATA_WIDTH-1:0] borrow_propagate,
    input                   borrow_in,
    output [DATA_WIDTH:0]   borrow_chain
);
    assign borrow_chain[0] = borrow_in;
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : gen_borrow_chain
            assign borrow_chain[i+1] = borrow_generate[i] | (borrow_propagate[i] & borrow_chain[i]);
        end
    endgenerate
endmodule

// -----------------------------------------------------------------------------
// Difference Calculation Submodule
// Computes the difference bits using two input vectors and the borrow chain
// -----------------------------------------------------------------------------
module diff_calc #(
    parameter DATA_WIDTH = 8
)(
    input  [DATA_WIDTH-1:0] minuend_in,
    input  [DATA_WIDTH-1:0] subtrahend_in,
    input  [DATA_WIDTH:0]   borrow_chain,
    output [DATA_WIDTH-1:0] difference_out
);
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin : gen_difference
            assign difference_out[i] = minuend_in[i] ^ subtrahend_in[i] ^ borrow_chain[i];
        end
    endgenerate
endmodule

// -----------------------------------------------------------------------------
// Parity Calculation Submodule
// Computes the parity bit (even/odd controlled by parameter)
// -----------------------------------------------------------------------------
module parity_calc #(
    parameter DATA_WIDTH = 8
)(
    input  [DATA_WIDTH-1:0] difference_in,
    input                   even_parity,
    output                  parity_bit
);
    wire parity_raw;
    assign parity_raw = ^difference_in;
    assign parity_bit = even_parity ? parity_raw : ~parity_raw;
endmodule