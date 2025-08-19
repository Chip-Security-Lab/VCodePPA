//SystemVerilog
module fraction_to_integer #(parameter INT_WIDTH=8, FRAC_WIDTH=8)(
    input wire [INT_WIDTH+FRAC_WIDTH-1:0] frac_in,
    output reg [INT_WIDTH-1:0] int_out
);
    wire round_bit;
    wire [INT_WIDTH-1:0] integer_part;
    wire [INT_WIDTH-1:0] round_bit_cond_inv;
    wire [INT_WIDTH-1:0] subtractor_result;
    wire carry_in;

    assign round_bit = frac_in[FRAC_WIDTH-1];
    assign integer_part = frac_in[INT_WIDTH+FRAC_WIDTH-1:FRAC_WIDTH];
    assign carry_in = round_bit;
    assign round_bit_cond_inv = round_bit ? {INT_WIDTH{1'b1}} : {INT_WIDTH{1'b0}};

    // Conditional Invert Subtractor: A - B = A + (~B) + 1 (if B=1), else A
    assign subtractor_result = integer_part + round_bit_cond_inv + carry_in;

    always @* begin
        int_out = subtractor_result;
    end
endmodule