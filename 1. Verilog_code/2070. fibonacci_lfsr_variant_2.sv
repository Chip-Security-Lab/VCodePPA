//SystemVerilog
module fibonacci_lfsr #(parameter WIDTH = 8) (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire [WIDTH-1:0] seed,
    input wire [WIDTH-1:0] polynomial,
    output wire [WIDTH-1:0] lfsr_out,
    output wire serial_out
);
    reg [WIDTH-1:0] lfsr_reg;
    wire feedback_bit;
    wire [WIDTH-1:0] lfsr_next;
    wire [WIDTH-1:0] minuend;
    wire [WIDTH-1:0] subtrahend;

    assign feedback_bit = ^(lfsr_reg & polynomial);
    assign serial_out = lfsr_reg[0];
    assign lfsr_out = lfsr_reg;

    assign minuend = lfsr_reg;
    assign subtrahend = polynomial;

    wire [WIDTH:0] conditional_sum;
    wire [WIDTH:0] generate_carry;

    // Conditional Sum Subtractor implementation for 8-bit
    assign generate_carry[0] = 1'b1; // Start with initial carry-in for subtraction (two's complement)
    assign conditional_sum[0] = minuend[0] ^ subtrahend[0] ^ 1'b1;
    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : gen_conditional_sum_subtractor
            wire a_bit, b_bit, prev_carry;
            assign a_bit = minuend[i];
            assign b_bit = subtrahend[i];
            assign prev_carry = generate_carry[i-1];
            assign conditional_sum[i] = a_bit ^ b_bit ^ prev_carry;
            assign generate_carry[i] = (~a_bit & (b_bit | prev_carry)) | (b_bit & prev_carry);
        end
    endgenerate
    assign conditional_sum[WIDTH] = 1'b0; // Unused, for width matching

    assign lfsr_next = conditional_sum[WIDTH-1:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr_reg <= seed;
        else if (enable)
            lfsr_reg <= {feedback_bit, lfsr_next[WIDTH-1:1]};
    end
endmodule