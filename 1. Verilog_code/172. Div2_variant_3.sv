//SystemVerilog
module Div2 #(parameter W=4)(
    input [W-1:0] a, b,
    output reg [W-1:0] q,
    output reg [W:0] r
);
    integer i;
    reg [W:0] r_next;
    reg [W-1:0] q_next;
    reg [W:0] sub_result;
    reg borrow;
    
    always @(*) begin
        r_next = a;
        q_next = 0;
        i = W-1;
        
        while(i >= 0) begin
            r_next = r_next << 1;
            
            // Conditional sum subtraction
            sub_result = r_next - b;
            borrow = (r_next < b);
            
            q_next[i] = ~borrow;
            r_next = borrow ? r_next : sub_result;
            
            i = i - 1;
        end
        
        q = q_next;
        r = r_next;
    end
endmodule