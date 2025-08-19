//SystemVerilog
module signed_divider_4bit_negative (
    input signed [3:0] a,
    input signed [3:0] b,
    output signed [3:0] quotient,
    output signed [3:0] remainder
);

    reg signed [3:0] dividend;
    reg signed [3:0] divisor;
    reg signed [3:0] q;
    reg signed [3:0] r;
    reg [2:0] count;
    
    always @(*) begin
        dividend = (a[3]) ? -a : a;
        divisor = (b[3]) ? -b : b;
    end
    
    always @(*) begin
        q = 0;
        r = 0;
        count = 0;
        
        while (count < 4) begin
            r = {r[2:0], dividend[3-count]};
            if (r >= divisor) begin
                r = r - divisor;
                q[3-count] = 1;
            end else begin
                q[3-count] = 0;
            end
            count = count + 1;
        end
    end
    
    assign quotient = (a[3] ^ b[3]) ? -q : q;
    assign remainder = (a[3]) ? -r : r;
    
endmodule