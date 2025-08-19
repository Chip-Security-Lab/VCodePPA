//SystemVerilog
module signed_divider_16bit (
    input signed [15:0] a,
    input signed [15:0] b,
    output signed [15:0] quotient,
    output signed [15:0] remainder
);

    wire a_sign, b_sign;
    wire [14:0] a_abs, b_abs;
    wire [14:0] quotient_abs, remainder_abs;
    wire quotient_sign, remainder_sign;

    // Sign detection
    assign a_sign = a[15];
    assign b_sign = b[15];

    // Absolute value calculation using explicit mux
    wire [14:0] a_neg, b_neg;
    assign a_neg = ~a[14:0] + 1'b1;
    assign b_neg = ~b[14:0] + 1'b1;
    
    assign a_abs = a_sign ? a_neg : a[14:0];
    assign b_abs = b_sign ? b_neg : b[14:0];

    // Division core
    reg [14:0] q, r;
    reg [14:0] temp_a;
    integer i;

    always @(*) begin
        q = 0;
        r = 0;
        temp_a = a_abs;
    end

    always @(*) begin
        for (i = 14; i >= 0; i = i - 1) begin
            r = {r[13:0], temp_a[i]};
            if (r >= b_abs) begin
                r = r - b_abs;
                q[i] = 1'b1;
            end
        end
    end

    assign quotient_abs = q;
    assign remainder_abs = r;

    // Result sign calculation
    assign quotient_sign = a_sign ^ b_sign;
    assign remainder_sign = a_sign;

    // Final result assembly using explicit mux
    wire [15:0] quotient_pos, quotient_neg;
    wire [15:0] remainder_pos, remainder_neg;
    
    assign quotient_pos = {1'b0, quotient_abs};
    assign quotient_neg = ~{1'b0, quotient_abs} + 1'b1;
    assign remainder_pos = {1'b0, remainder_abs};
    assign remainder_neg = ~{1'b0, remainder_abs} + 1'b1;

    assign quotient = quotient_sign ? quotient_neg : quotient_pos;
    assign remainder = remainder_sign ? remainder_neg : remainder_pos;

endmodule