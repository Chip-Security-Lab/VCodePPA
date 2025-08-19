module multiplier_8bit_step (
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] product
);
    integer i, j;
    always @(*) begin
        product = 0;
        for(i = 0; i < 8; i = i + 1) begin
            for(j = 0; j < 8; j = j + 1) begin
                if (a[i] & b[j]) product[i+j] = product[i+j] ^ 1;
            end
        end
    end
endmodule
