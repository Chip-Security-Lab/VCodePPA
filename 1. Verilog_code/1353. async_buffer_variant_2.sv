//SystemVerilog
module async_buffer (
    input wire [15:0] data_in,
    input wire [15:0] multiplier,
    input wire enable,
    output reg [31:0] data_out
);
    wire [31:0] product;
    
    karatsuba_multiplier_16bit karatsuba_inst (
        .a(data_in),
        .b(multiplier),
        .product(product)
    );
    
    always @(*) begin
        if (enable) begin
            data_out = product;
        end else begin
            data_out = 32'b0;
        end
    end
endmodule

module karatsuba_multiplier_16bit (
    input wire [15:0] a,
    input wire [15:0] b,
    output wire [31:0] product
);
    wire [7:0] a_high, a_low, b_high, b_low;
    wire [15:0] p1, p2, p3;
    wire [23:0] term1, term2, term3;
    
    assign a_high = a[15:8];
    assign a_low = a[7:0];
    assign b_high = b[15:8];
    assign b_low = b[7:0];
    
    // Recursive Karatsuba implementation
    karatsuba_multiplier_8bit karatsuba_high (
        .a(a_high),
        .b(b_high),
        .product(p1)
    );
    
    karatsuba_multiplier_8bit karatsuba_low (
        .a(a_low),
        .b(b_low),
        .product(p2)
    );
    
    karatsuba_multiplier_8bit karatsuba_mid (
        .a(a_high ^ a_low),
        .b(b_high ^ b_low),
        .product(p3)
    );
    
    assign term1 = {p1, 16'b0};
    assign term2 = {8'b0, p3 ^ p1 ^ p2, 8'b0};
    assign term3 = {16'b0, p2};
    
    assign product = term1 + term2 + term3;
endmodule

module karatsuba_multiplier_8bit (
    input wire [7:0] a,
    input wire [7:0] b,
    output wire [15:0] product
);
    wire [3:0] a_high, a_low, b_high, b_low;
    wire [7:0] p1, p2, p3;
    wire [11:0] term1, term2, term3;
    
    assign a_high = a[7:4];
    assign a_low = a[3:0];
    assign b_high = b[7:4];
    assign b_low = b[3:0];
    
    // Base case of recursion - use standard multiplier for 4-bit
    karatsuba_multiplier_4bit karatsuba_high (
        .a(a_high),
        .b(b_high),
        .product(p1)
    );
    
    karatsuba_multiplier_4bit karatsuba_low (
        .a(a_low),
        .b(b_low),
        .product(p2)
    );
    
    karatsuba_multiplier_4bit karatsuba_mid (
        .a(a_high ^ a_low),
        .b(b_high ^ b_low),
        .product(p3)
    );
    
    assign term1 = {p1, 8'b0};
    assign term2 = {4'b0, p3 ^ p1 ^ p2, 4'b0};
    assign term3 = {8'b0, p2};
    
    assign product = term1 + term2 + term3;
endmodule

module karatsuba_multiplier_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [7:0] product
);
    wire [1:0] a_high, a_low, b_high, b_low;
    wire [3:0] p1, p2, p3;
    wire [5:0] term1, term2, term3;
    
    assign a_high = a[3:2];
    assign a_low = a[1:0];
    assign b_high = b[3:2];
    assign b_low = b[1:0];
    
    // Base case - direct multiplication for 2-bit
    assign p1 = a_high * b_high;
    assign p2 = a_low * b_low;
    assign p3 = (a_high ^ a_low) * (b_high ^ b_low);
    
    assign term1 = {p1, 4'b0};
    assign term2 = {2'b0, p3 ^ p1 ^ p2, 2'b0};
    assign term3 = {4'b0, p2};
    
    assign product = term1 + term2 + term3;
endmodule