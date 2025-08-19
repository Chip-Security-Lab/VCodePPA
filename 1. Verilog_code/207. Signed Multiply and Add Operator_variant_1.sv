//SystemVerilog
module signed_multiply_add (
    input signed [7:0] a,
    input signed [7:0] b,
    input signed [7:0] c,
    output signed [15:0] result
);
    wire signed [15:0] mult_result;
    
    // Karatsuba multiplication implementation
    wire signed [3:0] a_high, a_low, b_high, b_low;
    wire signed [7:0] p1, p2, p3;
    wire signed [7:0] sum_a, sum_b;
    wire signed [7:0] p3_term;
    
    // Split input operands into high and low parts
    assign a_high = a[7:4];
    assign a_low = a[3:0];
    assign b_high = b[7:4];
    assign b_low = b[3:0];
    
    // Calculate intermediate products
    assign sum_a = a_high + a_low;
    assign sum_b = b_high + b_low;
    
    // Karatsuba algorithm components
    assign p1 = a_high * b_high;
    assign p2 = a_low * b_low;
    assign p3 = sum_a * sum_b;
    assign p3_term = p3 - p1 - p2;
    
    // Final multiplication result using Karatsuba algorithm
    assign mult_result = {p1, 8'b0} + {p3_term, 4'b0} + p2;
    
    // Add the third operand to complete the operation
    assign result = mult_result + c;
endmodule