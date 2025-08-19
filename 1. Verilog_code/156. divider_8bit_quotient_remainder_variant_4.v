module divider_8bit_quotient_remainder (
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] quotient,
    output reg [7:0] remainder
);

    reg [7:0] x0, x1, x2, x3;
    reg [15:0] temp1, temp2;
    reg [7:0] b_inv;
    reg [7:0] a_reg;
    reg [7:0] b_reg;
    
    // Dadda multiplier signals
    wire [15:0] dadda_prod1, dadda_prod2, dadda_prod3, dadda_prod4;
    wire [15:0] dadda_prod5, dadda_prod6, dadda_prod7;
    
    // Instantiate Dadda multipliers
    dadda_multiplier_8x8 mult1 (
        .a(x0),
        .b(2 - b_reg * x0),
        .prod(dadda_prod1)
    );
    
    dadda_multiplier_8x8 mult2 (
        .a(x1),
        .b(2 - b_reg * x1),
        .prod(dadda_prod2)
    );
    
    dadda_multiplier_8x8 mult3 (
        .a(x2),
        .b(2 - b_reg * x2),
        .prod(dadda_prod3)
    );
    
    dadda_multiplier_8x8 mult4 (
        .a(a_reg),
        .b(b_inv),
        .prod(dadda_prod4)
    );
    
    dadda_multiplier_8x8 mult5 (
        .a(quotient),
        .b(b_reg),
        .prod(dadda_prod5)
    );
    
    always @(*) begin
        a_reg = a;
        b_reg = b;
        
        // Initial guess: x0 = 1/b ≈ 1/256
        x0 = 8'b00000001;
        
        // First iteration
        x1 = dadda_prod1[15:8];
        
        // Second iteration
        x2 = dadda_prod2[15:8];
        
        // Third iteration
        x3 = dadda_prod3[15:8];
        
        // Final result
        b_inv = x3;
        quotient = dadda_prod4[15:8];
        remainder = a_reg - dadda_prod5[7:0];
    end
endmodule

module dadda_multiplier_8x8 (
    input [7:0] a,
    input [7:0] b,
    output [15:0] prod
);
    // Partial products
    wire [7:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7;
    
    // Generate partial products
    assign pp0 = a & {8{b[0]}};
    assign pp1 = (a & {8{b[1]}}) << 1;
    assign pp2 = (a & {8{b[2]}}) << 2;
    assign pp3 = (a & {8{b[3]}}) << 3;
    assign pp4 = (a & {8{b[4]}}) << 4;
    assign pp5 = (a & {8{b[5]}}) << 5;
    assign pp6 = (a & {8{b[6]}}) << 6;
    assign pp7 = (a & {8{b[7]}}) << 7;
    
    // Dadda tree reduction
    wire [15:0] sum1, carry1;
    wire [15:0] sum2, carry2;
    wire [15:0] sum3, carry3;
    
    // First stage
    assign sum1 = pp0 ^ pp1 ^ pp2;
    assign carry1 = (pp0 & pp1) | (pp0 & pp2) | (pp1 & pp2);
    
    // Second stage
    assign sum2 = sum1 ^ pp3 ^ pp4;
    assign carry2 = (sum1 & pp3) | (sum1 & pp4) | (pp3 & pp4);
    
    // Third stage
    assign sum3 = sum2 ^ pp5 ^ pp6;
    assign carry3 = (sum2 & pp5) | (sum2 & pp6) | (pp5 & pp6);
    
    // Final addition
    assign prod = sum3 + (carry3 << 1) + pp7;
endmodule