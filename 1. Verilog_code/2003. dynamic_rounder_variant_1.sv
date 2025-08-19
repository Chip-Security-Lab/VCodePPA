//SystemVerilog
module dynamic_rounder #(parameter W = 16) (
    input  [W+2:0] in,
    input          mode,
    output reg [W-1:0] out
);
    wire [W-1:0] truncated_value;
    wire         fractional_bit_present;
    wire [W-1:0] carry_generate;
    wire [W-1:0] carry_propagate;
    wire [W-1:0] carry;
    wire [W-1:0] rounded_sum;

    assign truncated_value      = in[W+2:3];
    assign fractional_bit_present = |in[2:0];

    // Carry Generate and Propagate for 3-bit carry-lookahead adder
    assign carry_generate[0] = truncated_value[0] & fractional_bit_present;
    assign carry_propagate[0] = truncated_value[0] ^ fractional_bit_present;
    assign carry[0] = fractional_bit_present;

    genvar i;
    generate
        for (i = 1; i < W; i = i + 1) begin : carry_chain
            assign carry_generate[i] = truncated_value[i] & 1'b0;
            assign carry_propagate[i] = truncated_value[i] ^ 1'b0;
            assign carry[i] = carry_generate[i-1] | (carry_propagate[i-1] & carry[i-1]);
        end
    endgenerate

    assign rounded_sum[0] = truncated_value[0] ^ fractional_bit_present;
    generate
        for (i = 1; i < W; i = i + 1) begin : sum_chain
            assign rounded_sum[i] = truncated_value[i] ^ carry[i-1];
        end
    endgenerate

    always @(*) begin
        if (mode) begin
            out = rounded_sum;
        end else begin
            out = truncated_value;
        end
    end
endmodule