//SystemVerilog
module fixed_point_round #(parameter IN_WIDTH=16, OUT_WIDTH=8)(
    input wire [IN_WIDTH-1:0] in_data,
    output reg [OUT_WIDTH-1:0] out_data,
    output reg overflow
);

    wire round_bit = (IN_WIDTH > OUT_WIDTH) ? in_data[IN_WIDTH-OUT_WIDTH-1] : 1'b0;
    wire [OUT_WIDTH-1:0] main_bits = in_data[IN_WIDTH-1:IN_WIDTH-OUT_WIDTH];
    wire [OUT_WIDTH:0] rounded_result;
    wire borrow_out;

    carry_lookahead_borrow_subtractor #(
        .WIDTH(OUT_WIDTH+1)
    ) cla_borrow_subtractor_inst (
        .minuend({1'b0, main_bits}),
        .subtrahend({1'b0, ~round_bit, {OUT_WIDTH-1{1'b1}}}),
        .diff(rounded_result),
        .borrow_out(borrow_out)
    );

    always @* begin
        if (OUT_WIDTH >= IN_WIDTH) begin
            out_data = {{(OUT_WIDTH-IN_WIDTH){in_data[IN_WIDTH-1]}}, in_data};
            overflow = 1'b0;
        end else begin
            out_data = rounded_result[OUT_WIDTH-1:0];
            overflow = (rounded_result[OUT_WIDTH] != rounded_result[OUT_WIDTH-1]);
        end
    end

endmodule

module carry_lookahead_borrow_subtractor #(parameter WIDTH=17)(
    input  wire [WIDTH-1:0] minuend,
    input  wire [WIDTH-1:0] subtrahend,
    output wire [WIDTH-1:0] diff,
    output wire borrow_out
);
    wire [WIDTH-1:0] generate_borrow;
    wire [WIDTH-1:0] propagate_borrow;
    wire [WIDTH:0] borrow_chain;

    assign borrow_chain[0] = 1'b0;

    integer idx;
    always @(*) begin : gen_borrow_block
        integer i;
        for (i = 0; i < WIDTH; i = i + 1) begin
            // placeholder to avoid latch inference
        end
    end

    // Replacing generate-for with while loop
    reg [WIDTH-1:0] generate_borrow_reg;
    reg [WIDTH-1:0] propagate_borrow_reg;
    reg [WIDTH:0] borrow_chain_reg;
    reg [WIDTH-1:0] diff_reg;

    integer j;

    always @(*) begin
        borrow_chain_reg[0] = 1'b0;
        j = 0;
        while (j < WIDTH) begin
            generate_borrow_reg[j] = (~minuend[j]) & subtrahend[j];
            propagate_borrow_reg[j] = ~(minuend[j] ^ subtrahend[j]);
            borrow_chain_reg[j+1] = generate_borrow_reg[j] | (propagate_borrow_reg[j] & borrow_chain_reg[j]);
            diff_reg[j] = minuend[j] ^ subtrahend[j] ^ borrow_chain_reg[j];
            j = j + 1;
        end
    end

    assign generate_borrow = generate_borrow_reg;
    assign propagate_borrow = propagate_borrow_reg;
    assign borrow_chain = borrow_chain_reg;
    assign diff = diff_reg;
    assign borrow_out = borrow_chain_reg[WIDTH];

endmodule