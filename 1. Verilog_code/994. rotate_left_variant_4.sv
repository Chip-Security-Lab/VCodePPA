//SystemVerilog
// Top module: rotate_left
module rotate_left(
    input  [31:0] data,
    input  [4:0]  amount,
    output [31:0] result
);
    assign result = (data << amount) | (data >> (32 - amount));
endmodule

// Fast Borrow Lookahead Subtractor (32-bit)
module borrow_lookahead_subtractor_32 (
    input  [31:0] minuend,
    input  [31:0] subtrahend,
    input         borrow_in,
    output [31:0] difference,
    output        borrow_out
);
    wire [31:0] generate_borrow;
    wire [31:0] propagate_borrow;
    wire [31:0] borrow_chain;

    assign generate_borrow   = (~minuend) & subtrahend;       // Generate: Gi = ~Ai & Bi
    assign propagate_borrow  = ~(minuend ^ subtrahend);       // Propagate: Pi = ~(Ai ^ Bi)

    assign borrow_chain[0] = generate_borrow[0] | (propagate_borrow[0] & borrow_in);

    genvar i;
    generate
        for (i = 1; i < 32; i = i + 1) begin : gen_borrow_chain
            assign borrow_chain[i] = generate_borrow[i] | (propagate_borrow[i] & borrow_chain[i-1]);
        end
    endgenerate

    assign difference = minuend ^ subtrahend ^ {borrow_chain[30:0], borrow_in};
    assign borrow_out = borrow_chain[31];
endmodule

// Rotate Right with Enable, using fast borrow lookahead subtractor for rotate amount calculation
module ror_module #(
    parameter WIDTH = 8
)(
    input clk, rst, en,
    input [WIDTH-1:0] data_in,
    input [$clog2(WIDTH)-1:0] rotate_by,
    output reg [WIDTH-1:0] data_out
);
    wire [$clog2(WIDTH)-1:0] rotate_amount;
    wire [$clog2(WIDTH)-1:0] width_value = WIDTH[$clog2(WIDTH)-1:0];
    wire borrow_unused;

    // Use fast borrow lookahead subtractor for (WIDTH - rotate_by)
    borrow_lookahead_subtractor_32 sub32_inst (
        .minuend    (width_value),
        .subtrahend ({{(32-$clog2(WIDTH)){1'b0}}, rotate_by}),
        .borrow_in  (1'b0),
        .difference (rotate_amount),
        .borrow_out (borrow_unused)
    );

    always @(posedge clk) begin
        if (rst) data_out <= {WIDTH{1'b0}};
        else if (en)
            data_out <= ({data_in, data_in} >> rotate_amount);
    end
endmodule