//SystemVerilog
module Div2 #(parameter W=4)(
    input [W-1:0] a, b,
    output reg [W-1:0] q,
    output reg [W:0] r
);
    reg [W:0] r_temp;
    reg [W-1:0] b_comp;
    reg borrow;
    integer i;
    
    always @(*) begin
        r = a;
        q = 0;
        i = W-1;
        
        while(i >= 0) begin
            r = r << 1;
            b_comp = ~b;
            borrow = 1'b1;
            
            // Conditional inversion subtractor
            r_temp = r + b_comp + borrow;
            q[i] = ~r_temp[W];
            
            if(q[i]) begin
                r = r_temp;
            end
            
            i = i - 1;
        end
    end
endmodule