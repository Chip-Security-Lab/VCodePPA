module multiplier_shift (
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] product
);
    integer i;
    always @(*) begin
        product = 0;
        for(i = 0; i < 8; i = i + 1) begin
            if(b[i]) product = product + (a << i);
        end
    end
endmodule
