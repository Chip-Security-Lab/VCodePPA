//SystemVerilog
module AlwaysNor(
    input  [7:0] a, 
    input  [7:0] b, 
    output reg [15:0] y
);
    reg [15:0] multiplicand;
    reg [7:0]  multiplier;
    reg [15:0] product;
    integer i;

    always @(*) begin
        multiplicand = {8'd0, a};
        multiplier   = b;
        product      = 16'd0;
        for (i = 0; i < 8; i = i + 1) begin
            if (multiplier[i])
                product = product + (multiplicand << i);
        end
        y = ~product;
    end
endmodule