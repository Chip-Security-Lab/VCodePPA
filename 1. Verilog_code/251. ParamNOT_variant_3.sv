//SystemVerilog
// SystemVerilog

// Submodule for calculating propagate and generate_b signals
module PropagateGenerate #(parameter WIDTH = 8) (
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] data_b,
    output [WIDTH-1:0] propagate,
    output [WIDTH-1:0] generate_b
);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : pg_calc
            assign propagate[i] = data_a[i] | data_b[i];
            assign generate_b[i] = ~data_a[i] & data_b[i];
        end
    endgenerate

endmodule

// Submodule for calculating borrow signals using lookahead logic
module BorrowLookahead #(parameter WIDTH = 8) (
    input [WIDTH-1:0] propagate,
    input [WIDTH-1:0] generate_b,
    output [WIDTH:0] borrow // borrow[0] is input, borrow[1..WIDTH] are outputs
);

    assign borrow[0] = 1'b0; // Initial borrow for subtraction

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : borrow_calc
            // Borrow_i+1 = G_i + P_i * Borrow_i
            assign borrow[i+1] = (i == 0) ? generate_b[i] : (generate_b[i] | (propagate[i] & borrow[i]));
        end
    endgenerate

endmodule

// Top-level module for subtraction with borrow lookahead
module ParamSUB_Hierarchical #(parameter WIDTH = 8) (
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] data_b,
    output [WIDTH-1:0] data_out,
    output borrow_out
);

    // Internal wires
    wire [WIDTH-1:0] propagate_w;
    wire [WIDTH-1:0] generate_b_w;
    wire [WIDTH:0] borrow_w;

    // Instantiate submodules
    PropagateGenerate #(
        .WIDTH(WIDTH)
    ) u_propagate_generate (
        .data_a(data_a),
        .data_b(data_b),
        .propagate(propagate_w),
        .generate_b(generate_b_w)
    );

    BorrowLookahead #(
        .WIDTH(WIDTH)
    ) u_borrow_lookahead (
        .propagate(propagate_w),
        .generate_b(generate_b_w),
        .borrow(borrow_w)
    );

    // Calculate the difference (output)
    assign data_out = data_a ^ data_b ^ borrow_w[0+:WIDTH]; // Difference_i = A_i ^ B_i ^ Borrow_i

    // Output the final borrow
    assign borrow_out = borrow_w[WIDTH];

endmodule