//SystemVerilog
module AsyncRst_NAND(
    input rst_n,
    input [3:0] src1, src2,
    output reg [7:0] q
);
    wire [7:0] mult_result;
    
    karatsuba_multiplier_4bit kmult (
        .a(src1),
        .b(src2),
        .p(mult_result)
    );
    
    always @(*) begin
        if (rst_n) begin
            q = mult_result;
        end else begin
            q = 8'hFF;
        end
    end
endmodule

module karatsuba_multiplier_4bit(
    input [3:0] a,
    input [3:0] b,
    output [7:0] p
);
    wire [1:0] a_high, a_low, b_high, b_low;
    wire [3:0] p1, p2, p3;
    wire [3:0] sum_a, sum_b;
    wire [3:0] term3;
    
    assign a_high = a[3:2];
    assign a_low = a[1:0];
    assign b_high = b[3:2];
    assign b_low = b[1:0];
    
    // Calculate sub-products
    karatsuba_multiplier_2bit km1 (
        .a(a_high),
        .b(b_high),
        .p(p1)
    );
    
    karatsuba_multiplier_2bit km2 (
        .a(a_low),
        .b(b_low),
        .p(p2)
    );
    
    assign sum_a = {2'b00, a_high} + {2'b00, a_low};
    assign sum_b = {2'b00, b_high} + {2'b00, b_low};
    
    karatsuba_multiplier_2bit km3 (
        .a(sum_a[1:0]),
        .b(sum_b[1:0]),
        .p(p3)
    );
    
    assign term3 = p3 - p1 - p2;
    
    // Combine results using Karatsuba algorithm
    assign p = {p1, 4'b0000} + {2'b00, term3, 2'b00} + {4'b0000, p2};
endmodule

module karatsuba_multiplier_2bit(
    input [1:0] a,
    input [1:0] b,
    output [3:0] p
);
    wire a0, a1, b0, b1;
    wire p0, p1, p2;
    wire s_a, s_b, s_p;
    
    assign a0 = a[0];
    assign a1 = a[1];
    assign b0 = b[0];
    assign b1 = b[1];
    
    // Basic multiplications
    assign p0 = a0 & b0;
    assign p2 = a1 & b1;
    
    assign s_a = a0 ^ a1;
    assign s_b = b0 ^ b1;
    assign s_p = s_a & s_b;
    
    assign p1 = s_p ^ p0 ^ p2;
    
    // Combine results
    assign p = {2'b00, p2, 1'b0} + {1'b0, p1, 1'b0} + {3'b000, p0};
endmodule