module xor_iterative(
    input [3:0] x,
    input [3:0] y,
    output reg [3:0] z
);
    integer i;
    always @(*) begin
        for(i=0; i<4; i=i+1)
            z[i] = x[i] ^ y[i];
    end
endmodule