//SystemVerilog
module karatsuba_multiplier_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    output reg [15:0] product
);

    // Internal signals for recursive calls
    wire [3:0] a_high = a[7:4];
    wire [3:0] a_low = a[3:0];
    wire [3:0] b_high = b[7:4];
    wire [3:0] b_low = b[3:0];
    
    // Partial products
    wire [7:0] p0, p1, p2;
    wire [7:0] sum_a, sum_b;
    wire [7:0] p3;
    
    // Recursive 4-bit multipliers
    karatsuba_multiplier_4bit mult0 (
        .a(a_low),
        .b(b_low),
        .product(p0)
    );
    
    karatsuba_multiplier_4bit mult1 (
        .a(a_high),
        .b(b_high),
        .product(p1)
    );
    
    karatsuba_multiplier_4bit mult2 (
        .a(a_high + a_low),
        .b(b_high + b_low),
        .product(p2)
    );
    
    // Final product calculation
    always @* begin
        product = (p1 << 8) + ((p2 - p1 - p0) << 4) + p0;
    end

endmodule

module karatsuba_multiplier_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output reg [7:0] product
);

    // Internal signals for recursive calls
    wire [1:0] a_high = a[3:2];
    wire [1:0] a_low = a[1:0];
    wire [1:0] b_high = b[3:2];
    wire [1:0] b_low = b[1:0];
    
    // Partial products
    wire [3:0] p0, p1, p2;
    wire [3:0] sum_a, sum_b;
    wire [3:0] p3;
    
    // Base case: 2-bit multipliers
    assign p0 = a_low * b_low;
    assign p1 = a_high * b_high;
    assign p2 = (a_high + a_low) * (b_high + b_low);
    
    // Final product calculation
    always @* begin
        product = (p1 << 4) + ((p2 - p1 - p0) << 2) + p0;
    end

endmodule