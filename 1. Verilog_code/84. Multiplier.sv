module Multiplier4(
    input [3:0] a, b,
    output [7:0] result
);
    reg [7:0] acc;
    integer i;
    
    always @(*) begin
        acc = 0;
        for(i=0; i<4; i=i+1)
            acc = acc + (b[i] ? (a << i) : 0);
    end
    assign result = acc;
endmodule