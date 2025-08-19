//SystemVerilog
module signed_multiply_add (
    input  logic signed [7:0] a,
    input  logic signed [7:0] b,
    input  logic signed [7:0] c,
    output logic signed [15:0] result
);

    // Stage 1: Input Splitting
    logic signed [3:0] a_high, a_low, b_high, b_low;
    logic signed [4:0] a_sum, b_sum;
    
    always_comb begin
        a_high = a[7:4];
        a_low  = a[3:0];
        b_high = b[7:4];
        b_low  = b[3:0];
        a_sum  = a_high + a_low;
        b_sum  = b_high + b_low;
    end

    // Stage 2: Partial Products
    logic signed [7:0] p1, p2, p3;
    
    always_comb begin
        p1 = a_high * b_high;
        p2 = a_low * b_low;
        p3 = (a_sum * b_sum) - p1 - p2;
    end

    // Stage 3: Product Assembly
    logic signed [15:0] mult_result;
    
    always_comb begin
        mult_result = {p1, 8'b0} + {4'b0, p3, 4'b0} + {8'b0, p2};
    end

    // Stage 4: Final Addition
    always_comb begin
        result = mult_result + {{8{c[7]}}, c};
    end

endmodule