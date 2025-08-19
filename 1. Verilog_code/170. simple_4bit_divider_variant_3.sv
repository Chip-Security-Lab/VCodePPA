//SystemVerilog
module simple_4bit_divider (
    input [3:0] a,
    input [3:0] b,
    output reg [3:0] quotient,
    output reg [3:0] remainder
);

    reg [3:0] dividend;
    reg [3:0] divisor;
    reg [3:0] temp_quotient;
    reg [3:0] temp_remainder;
    reg [3:0] next_remainder;
    reg [3:0] next_quotient;
    reg [3:0] shifted_remainder;
    reg [3:0] diff;

    always @(*) begin
        dividend = a;
        divisor = b;
        temp_quotient = 4'b0;
        temp_remainder = 4'b0;
        next_remainder = 4'b0;
        next_quotient = 4'b0;

        // Stage 0
        shifted_remainder = {temp_remainder[2:0], dividend[3]};
        diff = shifted_remainder - divisor;
        next_remainder = (diff[3] == 1'b0) ? diff : shifted_remainder;
        next_quotient[3] = ~diff[3];

        // Stage 1
        shifted_remainder = {next_remainder[2:0], dividend[2]};
        diff = shifted_remainder - divisor;
        next_remainder = (diff[3] == 1'b0) ? diff : shifted_remainder;
        next_quotient[2] = ~diff[3];

        // Stage 2
        shifted_remainder = {next_remainder[2:0], dividend[1]};
        diff = shifted_remainder - divisor;
        next_remainder = (diff[3] == 1'b0) ? diff : shifted_remainder;
        next_quotient[1] = ~diff[3];

        // Stage 3
        shifted_remainder = {next_remainder[2:0], dividend[0]};
        diff = shifted_remainder - divisor;
        next_remainder = (diff[3] == 1'b0) ? diff : shifted_remainder;
        next_quotient[0] = ~diff[3];

        quotient = next_quotient;
        remainder = next_remainder;
    end

endmodule