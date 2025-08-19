//SystemVerilog
// Top-level module: Parity Generator with Hierarchical Structure

module parity_generator #(
    parameter DATA_WIDTH = 8,
    parameter EVEN_PARITY = 1  // 1: even parity, 0: odd parity
)(
    input  wire [DATA_WIDTH-1:0] data,
    output wire                  parity_bit
);

    // Internal signals for inter-module connections
    wire raw_parity;
    wire [DATA_WIDTH-1:0] even_parity_val;
    wire [DATA_WIDTH-1:0] odd_parity_val;
    wire even_parity_bit;
    wire odd_parity_bit;

    // Parity calculation submodule
    parity_calc #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_parity_calc (
        .data_in   (data),
        .parity_out(raw_parity)
    );

    // Even parity value generator submodule
    even_parity_gen #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_even_parity_gen (
        .raw_parity_in (raw_parity),
        .even_val_out  (even_parity_val)
    );

    // Odd parity value generator submodule
    odd_parity_gen #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_odd_parity_gen (
        .even_val_in (even_parity_val),
        .odd_val_out (odd_parity_val)
    );

    // Parity selection submodule
    parity_select u_parity_select (
        .even_bit_in (even_parity_val[0]),
        .odd_bit_in  (odd_parity_val[0]),
        .even_parity_sel(EVEN_PARITY),
        .parity_bit_out (parity_bit)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: parity_calc
// Purpose : Computes XOR reduction (raw parity) of the input data vector
// -----------------------------------------------------------------------------
module parity_calc #(
    parameter DATA_WIDTH = 8
)(
    input  wire [DATA_WIDTH-1:0] data_in,
    output wire                  parity_out
);
    assign parity_out = ^data_in;
endmodule

// -----------------------------------------------------------------------------
// Submodule: even_parity_gen
// Purpose : Generates even parity value (zero-extended raw parity)
// -----------------------------------------------------------------------------
module even_parity_gen #(
    parameter DATA_WIDTH = 8
)(
    input  wire                  raw_parity_in,
    output wire [DATA_WIDTH-1:0] even_val_out
);
    assign even_val_out = { {DATA_WIDTH-1{1'b0}}, raw_parity_in };
endmodule

// -----------------------------------------------------------------------------
// Submodule: odd_parity_gen
// Purpose : Generates odd parity value using two's complement addition
// -----------------------------------------------------------------------------
module odd_parity_gen #(
    parameter DATA_WIDTH = 8
)(
    input  wire [DATA_WIDTH-1:0] even_val_in,
    output wire [DATA_WIDTH-1:0] odd_val_out
);
    assign odd_val_out = even_val_in + {{(DATA_WIDTH-1){1'b0}}, 1'b1};
endmodule

// -----------------------------------------------------------------------------
// Submodule: parity_select
// Purpose : Selects even or odd parity bit based on control input
// -----------------------------------------------------------------------------
module parity_select (
    input  wire even_bit_in,
    input  wire odd_bit_in,
    input  wire even_parity_sel, // 1: select even, 0: select odd
    output wire parity_bit_out
);
    assign parity_bit_out = (even_parity_sel) ? even_bit_in : odd_bit_in;
endmodule