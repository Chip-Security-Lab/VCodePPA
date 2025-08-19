//SystemVerilog
module fsm_divider_4bit (
    input clk,
    input reset,
    input [3:0] a,
    input [3:0] b,
    output reg [3:0] quotient,
    output reg [3:0] remainder
);

    reg [3:0] state;
    reg [3:0] partial_remainder;
    reg [3:0] divisor;
    reg [3:0] dividend;
    reg [2:0] iteration;
    reg [3:0] next_quotient;
    reg [3:0] next_remainder;
    wire [3:0] partial_remainder_shifted;
    wire [3:0] dividend_shifted;
    wire [3:0] next_quotient_shifted;
    wire [3:0] partial_remainder_sub;
    wire partial_remainder_ge_divisor;

    assign partial_remainder_shifted = {partial_remainder[2:0], dividend[3]};
    assign dividend_shifted = {dividend[2:0], 1'b0};
    assign next_quotient_shifted = {next_quotient[2:0], 1'b1};
    assign partial_remainder_sub = partial_remainder - divisor;
    assign partial_remainder_ge_divisor = (partial_remainder >= divisor);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
            state <= 0;
            partial_remainder <= 0;
            divisor <= 0;
            dividend <= 0;
            iteration <= 0;
            next_quotient <= 0;
            next_remainder <= 0;
        end else begin
            case (state)
                0: begin
                    dividend <= a;
                    divisor <= b;
                    partial_remainder <= 0;
                    iteration <= 0;
                    next_quotient <= 0;
                    state <= 1;
                end
                1: begin
                    if (iteration < 4) begin
                        partial_remainder <= partial_remainder_ge_divisor ? 
                            partial_remainder_sub : partial_remainder_shifted;
                        dividend <= dividend_shifted;
                        next_quotient <= partial_remainder_ge_divisor ? 
                            next_quotient_shifted : {next_quotient[2:0], 1'b0};
                        iteration <= iteration + 1;
                    end else begin
                        quotient <= next_quotient;
                        remainder <= partial_remainder;
                        state <= 2;
                    end
                end
                2: begin
                    state <= 0;
                end
            endcase
        end
    end
endmodule