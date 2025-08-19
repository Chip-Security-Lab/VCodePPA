//SystemVerilog
// Top-level module: Hierarchical binary to excess-N code converter
module binary_to_excess_n #(parameter WIDTH=8, N=127)(
    input wire [WIDTH-1:0] binary_in,
    output wire [WIDTH-1:0] excess_n_out
);

    wire [WIDTH-1:0] addend;
    wire [WIDTH-1:0] sum;

    // Submodule: Constant generator for parameter N
    constant_generator #(
        .WIDTH(WIDTH),
        .N(N)
    ) u_constant_generator (
        .const_out(addend)
    );

    // Submodule: Adder for binary plus N
    binary_adder #(
        .WIDTH(WIDTH)
    ) u_binary_adder (
        .a(binary_in),
        .b(addend),
        .sum(sum)
    );

    assign excess_n_out = sum;

endmodule

// Submodule: Constant Generator
// Generates a constant value N of width WIDTH
module constant_generator #(parameter WIDTH=8, N=127)(
    output wire [WIDTH-1:0] const_out
);
    assign const_out = N[WIDTH-1:0];
endmodule

// Submodule: Binary Adder
// Adds two WIDTH-bit inputs and outputs the WIDTH-bit sum
module binary_adder #(parameter WIDTH=8)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] sum
);
    assign sum = a + b;
endmodule