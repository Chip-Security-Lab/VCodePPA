module IterNor(input [7:0] a, b, output reg [7:0] y);
    integer i;
    always @(*) begin
        for(i=0; i<8; i=i+1)
            y[i] = ~(a[i] | b[i]);
    end
endmodule