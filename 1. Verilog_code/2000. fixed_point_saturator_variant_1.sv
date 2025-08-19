//SystemVerilog
module fixed_point_saturator #(
    parameter IN_WIDTH = 16, 
    parameter OUT_WIDTH = 8
)(
    input  wire signed [IN_WIDTH-1:0] in_data,
    output reg  signed [OUT_WIDTH-1:0] out_data,
    output reg  overflow
);
    // Maximum and minimum values for saturation
    wire signed [OUT_WIDTH-1:0] max_value = {1'b0, {(OUT_WIDTH-1){1'b1}}};
    wire signed [OUT_WIDTH-1:0] min_value = {1'b1, {(OUT_WIDTH-1){1'b0}}};

    // Preprocessing for overflow detection
    wire [IN_WIDTH-OUT_WIDTH+1:0] upper_bits = in_data[IN_WIDTH-1:OUT_WIDTH-1];
    wire upper_bits_all_ones  = &upper_bits;
    wire upper_bits_all_zeros = ~|upper_bits;
    wire upper_bits_same      = upper_bits_all_ones | upper_bits_all_zeros;

    // Internal signals for parallel borrow lookahead subtraction
    wire [OUT_WIDTH-1:0] a_sub;
    wire [OUT_WIDTH-1:0] b_sub;
    wire [OUT_WIDTH-1:0] diff_sub;
    wire [OUT_WIDTH:0]   borrow_chain;

    assign a_sub = in_data[OUT_WIDTH-1:0];
    assign b_sub = {OUT_WIDTH{1'b0}};
    assign borrow_chain[0] = 1'b0;

    genvar i;
    generate
        for(i = 0; i < OUT_WIDTH; i = i + 1) begin : borrow_lookahead
            wire generate_borrow = (~a_sub[i]) & b_sub[i];
            wire propagate_borrow = ~(a_sub[i] ^ b_sub[i]);
            assign borrow_chain[i+1] = generate_borrow | (propagate_borrow & borrow_chain[i]);
            assign diff_sub[i] = a_sub[i] ^ b_sub[i] ^ borrow_chain[i];
        end
    endgenerate

    always @* begin
        overflow = ~upper_bits_same;
        if (in_data[IN_WIDTH-1] == 1'b0 && overflow) begin
            out_data = max_value;
        end else if (in_data[IN_WIDTH-1] == 1'b1 && overflow) begin
            out_data = min_value;
        end else begin
            out_data = diff_sub;
        end
    end

endmodule