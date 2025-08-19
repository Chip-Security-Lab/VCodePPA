//SystemVerilog
module simple_4bit_divider (
    input [3:0] a,
    input [3:0] b,
    output [3:0] quotient,
    output [3:0] remainder
);

    divider_core u_divider_core (
        .dividend(a),
        .divisor(b),
        .quotient(quotient),
        .remainder(remainder)
    );

endmodule

module divider_core (
    input [3:0] dividend,
    input [3:0] divisor,
    output [3:0] quotient,
    output [3:0] remainder
);

    reg [3:0] q;
    reg [3:0] r;
    reg [3:0] temp_dividend;
    reg [3:0] temp_divisor;
    integer i;

    always @(*) begin
        temp_dividend = dividend;
        temp_divisor = divisor;
        q = 4'b0;
        r = 4'b0;
        i = 3;

        while (i >= 0) begin
            r = r << 1;
            r[0] = temp_dividend[i];
            
            if (r >= temp_divisor) begin
                r = r - temp_divisor;
                q[i] = 1'b1;
            end
            
            i = i - 1;
        end
    end

    assign quotient = q;
    assign remainder = r;

endmodule