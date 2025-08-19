module subtractor_4bit_sync (
    input clk, 
    input reset, 
    input [3:0] a, 
    input [3:0] b, 
    output reg [3:0] diff
);

    wire [3:0] b_inv = ~b;
    wire [3:0] p = a ^ b_inv;
    wire [3:0] g = a & b_inv;
    
    wire [3:0] carry;
    wire [3:0] diff_next;
    
    // Optimized carry computation
    assign carry[0] = 1'b0;
    assign carry[1] = g[0];
    assign carry[2] = g[1] | (p[1] & g[0]);
    assign carry[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    
    // Optimized difference computation
    assign diff_next = p ^ carry;
    
    always @(posedge clk or posedge reset) begin
        if (reset) diff <= 0;
        else diff <= diff_next;
    end
    
endmodule