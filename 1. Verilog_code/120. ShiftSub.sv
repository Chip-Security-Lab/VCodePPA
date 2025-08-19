module ShiftSub(input [7:0] a, b, output reg [7:0] res);
    integer i;
    
    always @(*) begin
        res = a; // Initialize result with input a
        for(i=0; i<8; i=i+1) 
            if(res >= (b<<i)) res = res - (b<<i);
    end
endmodule