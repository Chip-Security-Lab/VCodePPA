//SystemVerilog
module signed_divider_8bit_negative (
    input signed [7:0] a,
    input signed [7:0] b,
    output signed [7:0] quotient,
    output signed [7:0] remainder
);

    wire [6:0] abs_a = a[7] ? -a[6:0] : a[6:0];
    wire [6:0] abs_b = b[7] ? -b[6:0] : b[6:0];
    wire a_sign = a[7];
    wire b_sign = b[7];

    wire [6:0] unsigned_quotient;
    wire [6:0] unsigned_remainder;
    
    unsigned_divider_7bit unsigned_divider_inst (
        .a(abs_a),
        .b(abs_b),
        .quotient(unsigned_quotient),
        .remainder(unsigned_remainder)
    );

    wire quotient_sign = a_sign ^ b_sign;
    assign quotient = {quotient_sign, unsigned_quotient};
    assign remainder = {a_sign, unsigned_remainder};

endmodule

module unsigned_divider_7bit (
    input [6:0] a,
    input [6:0] b,
    output [6:0] quotient,
    output [6:0] remainder
);
    reg [6:0] q;
    reg [6:0] r;
    reg [6:0] temp_a;
    reg [6:0] temp_b;
    reg borrow;
    integer i;

    always @(*) begin
        q = 0;
        r = 0;
        temp_a = a;
        temp_b = b;
        
        for (i = 6; i >= 0; i = i - 1) begin
            r = {r[5:0], temp_a[i]};
            if (r >= temp_b) begin
                // Borrow subtractor implementation
                borrow = 0;
                for (int j = 0; j < 7; j = j + 1) begin
                    r[j] = r[j] ^ temp_b[j] ^ borrow;
                    borrow = (~r[j] & temp_b[j]) | (~r[j] & borrow) | (temp_b[j] & borrow);
                end
                q[i] = 1'b1;
            end
        end
    end

    assign quotient = q;
    assign remainder = r;
endmodule