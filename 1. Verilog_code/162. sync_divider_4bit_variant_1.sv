//SystemVerilog
module sync_divider_4bit (
    input clk,
    input reset,
    input [3:0] a,
    input [3:0] b,
    output reg [3:0] quotient
);

    // Parallel prefix adder implementation for division
    reg [3:0] partial_quotient;
    reg [3:0] remainder;
    reg [3:0] next_quotient;
    reg [3:0] next_remainder;
    
    // Generate and propagate signals for parallel prefix adder
    wire [3:0] g, p;
    wire [3:0] carry;
    
    // Generate and propagate computation
    assign g[0] = a[0] & ~b[0];
    assign p[0] = a[0] ^ ~b[0];
    
    assign g[1] = a[1] & ~b[1];
    assign p[1] = a[1] ^ ~b[1];
    
    assign g[2] = a[2] & ~b[2];
    assign p[2] = a[2] ^ ~b[2];
    
    assign g[3] = a[3] & ~b[3];
    assign p[3] = a[3] ^ ~b[3];
    
    // Parallel prefix computation
    wire [3:0] g_prefix, p_prefix;
    
    // First level
    assign g_prefix[0] = g[0];
    assign p_prefix[0] = p[0];
    
    assign g_prefix[1] = g[1] | (p[1] & g[0]);
    assign p_prefix[1] = p[1] & p[0];
    
    assign g_prefix[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign p_prefix[2] = p[2] & p[1] & p[0];
    
    assign g_prefix[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    assign p_prefix[3] = p[3] & p[2] & p[1] & p[0];
    
    // Carry computation
    assign carry[0] = g_prefix[0];
    assign carry[1] = g_prefix[1];
    assign carry[2] = g_prefix[2];
    assign carry[3] = g_prefix[3];
    
    // Sum computation
    wire [3:0] sum;
    assign sum[0] = p[0] ^ 1'b0;
    assign sum[1] = p[1] ^ carry[0];
    assign sum[2] = p[2] ^ carry[1];
    assign sum[3] = p[3] ^ carry[2];
    
    // Division logic
    always @(*) begin
        if (b == 0) begin
            next_quotient = 4'b1111; // Handle divide by zero
            next_remainder = 4'b0000;
        end else begin
            // Initial guess for quotient
            next_quotient = sum;
            
            // Adjust quotient if needed
            if (next_quotient * b > a) begin
                next_quotient = next_quotient - 1;
            end
            
            // Calculate remainder
            next_remainder = a - (next_quotient * b);
        end
    end
    
    // Sequential logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            quotient <= 0;
            remainder <= 0;
        end else begin
            quotient <= next_quotient;
            remainder <= next_remainder;
        end
    end

endmodule