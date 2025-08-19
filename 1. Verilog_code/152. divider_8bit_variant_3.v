module divider_8bit (
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    reg [7:0] dividend;
    reg [7:0] divisor;
    reg [7:0] q;
    reg [7:0] r;
    reg [2:0] count;
    
    always @(*) begin
        dividend = a;
        divisor = b;
        q = 0;
        r = 0;
        
        // Unrolled loop for better performance
        // Iteration 0
        r = {r[6:0], dividend[7]};
        dividend = {dividend[6:0], 1'b0};
        if(r >= divisor) begin
            r = r - divisor;
            q = {q[6:0], 1'b1};
        end else begin
            q = {q[6:0], 1'b0};
        end
        
        // Iteration 1
        r = {r[6:0], dividend[7]};
        dividend = {dividend[6:0], 1'b0};
        if(r >= divisor) begin
            r = r - divisor;
            q = {q[6:0], 1'b1};
        end else begin
            q = {q[6:0], 1'b0};
        end
        
        // Iteration 2
        r = {r[6:0], dividend[7]};
        dividend = {dividend[6:0], 1'b0};
        if(r >= divisor) begin
            r = r - divisor;
            q = {q[6:0], 1'b1};
        end else begin
            q = {q[6:0], 1'b0};
        end
        
        // Iteration 3
        r = {r[6:0], dividend[7]};
        dividend = {dividend[6:0], 1'b0};
        if(r >= divisor) begin
            r = r - divisor;
            q = {q[6:0], 1'b1};
        end else begin
            q = {q[6:0], 1'b0};
        end
        
        // Iteration 4
        r = {r[6:0], dividend[7]};
        dividend = {dividend[6:0], 1'b0};
        if(r >= divisor) begin
            r = r - divisor;
            q = {q[6:0], 1'b1};
        end else begin
            q = {q[6:0], 1'b0};
        end
        
        // Iteration 5
        r = {r[6:0], dividend[7]};
        dividend = {dividend[6:0], 1'b0};
        if(r >= divisor) begin
            r = r - divisor;
            q = {q[6:0], 1'b1};
        end else begin
            q = {q[6:0], 1'b0};
        end
        
        // Iteration 6
        r = {r[6:0], dividend[7]};
        dividend = {dividend[6:0], 1'b0};
        if(r >= divisor) begin
            r = r - divisor;
            q = {q[6:0], 1'b1};
        end else begin
            q = {q[6:0], 1'b0};
        end
        
        // Iteration 7
        r = {r[6:0], dividend[7]};
        dividend = {dividend[6:0], 1'b0};
        if(r >= divisor) begin
            r = r - divisor;
            q = {q[6:0], 1'b1};
        end else begin
            q = {q[6:0], 1'b0};
        end
    end
    
    always @(*) begin
        quotient = q;
        remainder = r;
    end

endmodule