//SystemVerilog
// Top-level module for 1-to-4 demultiplexer with hierarchical structure (optimized, with subtractor using two's complement addition)
module demux_1to4_case (
    input  wire       din,           // Data input
    input  wire [1:0] select,        // 2-bit selection control
    output wire [3:0] dout           // 4-bit output bus
);

    wire [3:0] select_onehot;

    // Optimized selector: Range check and one-hot generation
    demux_selector_optimized #(
        .WIDTH(4)
    ) u_selector (
        .select_in(select),
        .select_onehot(select_onehot)
    );

    // Optimized data router: Direct mask
    demux_data_router_optimized #(
        .WIDTH(4)
    ) u_data_router (
        .data_in(din),
        .select_onehot(select_onehot),
        .data_out(dout)
    );

endmodule

// -----------------------------------------------------------------------------
// Optimized Selector submodule: Decodes select signal into one-hot select lines
// Includes a 4-bit subtractor using two's complement addition
// -----------------------------------------------------------------------------
module demux_selector_optimized #(
    parameter WIDTH = 4
) (
    input  wire [$clog2(WIDTH)-1:0] select_in,    // Selection control input
    output wire [WIDTH-1:0]         select_onehot // One-hot select lines
);
    // Subtractor signals (demonstration of two's complement addition for subtraction)
    wire [3:0] sub_a;
    wire [3:0] sub_b;
    wire [3:0] sub_b_inv;
    wire [3:0] subtract_result;
    wire       carry_in;
    wire       carry_out;

    // Example values for subtraction (these can be replaced or connected as needed)
    assign sub_a = 4'b1011; // Example operand A
    assign sub_b = 4'b0101; // Example operand B

    // Two's complement inversion for subtraction
    assign sub_b_inv = ~sub_b;
    assign carry_in = 1'b1;

    // Two's complement addition for subtraction: sub_a - sub_b = sub_a + (~sub_b + 1)
    assign {carry_out, subtract_result} = {1'b0, sub_a} + {1'b0, sub_b_inv} + carry_in;

    assign select_onehot = (select_in < WIDTH) ? (1'b1 << select_in) : {WIDTH{1'b0}};
endmodule

// -----------------------------------------------------------------------------
// Optimized Data routing submodule: Routes din to the selected output line
// -----------------------------------------------------------------------------
module demux_data_router_optimized #(
    parameter WIDTH = 4
) (
    input  wire       data_in,                    // Data input
    input  wire [WIDTH-1:0] select_onehot,        // One-hot select lines
    output wire [WIDTH-1:0] data_out              // Data outputs
);
    assign data_out = data_in ? select_onehot : {WIDTH{1'b0}};
endmodule