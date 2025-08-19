module Div2 #(parameter W=4)(
    input [W-1:0] a, b,
    output reg [W-1:0] q,
    output reg [W:0] r
);
    integer i;
    always @(*) begin
        r = a;
        q = 0;
        for(i=W-1; i>=0; i=i-1) begin
            r = r << 1;
            q[i] = (r >= b);
            if(q[i]) r = r - b;
        end
    end
endmodule