module xor_behavioral(input a, b, output reg y);
    always @(*) begin
        y = (a & ~b) | (~a & b);
    end
endmodule