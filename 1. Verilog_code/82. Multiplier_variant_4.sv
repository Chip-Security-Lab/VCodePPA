//SystemVerilog
module Multiplier2#(parameter WIDTH=4)(
    input [WIDTH-1:0] x, y,
    output [2*WIDTH-1:0] product
);
    reg [2*WIDTH-1:0] product_reg;
    reg [2*WIDTH-1:0] partial_sum;
    reg [WIDTH-1:0] multiplicand;
    integer i;
    
    always @(*) begin
        product_reg = 0;
        multiplicand = x;
        partial_sum = 0;
        i = 0;
        
        while (i < WIDTH) begin
            if (y[i]) begin
                partial_sum = partial_sum + (multiplicand << i);
            end
            i = i + 1;
        end
        
        product_reg = partial_sum;
    end
    
    assign product = product_reg;
endmodule