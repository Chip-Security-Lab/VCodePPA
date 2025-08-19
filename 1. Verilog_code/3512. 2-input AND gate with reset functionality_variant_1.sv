//SystemVerilog
module and_gate_reset (
    input wire [7:0] a,      // Input A (expanded to 8-bit)
    input wire [7:0] b,      // Input B (expanded to 8-bit)
    input wire rst,          // Reset signal
    output reg [15:0] y      // Output Y (expanded to 16-bit result)
);
    // Internal signals for Karatsuba multiplication
    wire [3:0] a_high, a_low, b_high, b_low;
    wire [7:0] p_high, p_low, p_mid;
    wire [7:0] sum_a, sum_b;
    wire [7:0] p_mid_term;
    
    // Split inputs into high and low parts
    assign a_high = a[7:4];
    assign a_low = a[3:0];
    assign b_high = b[7:4];
    assign b_low = b[3:0];
    
    // Calculate sums for middle term
    assign sum_a = a_high + a_low;
    assign sum_b = b_high + b_low;
    
    // Instantiate submultipliers
    karatsuba_submult #(4) high_mult (
        .a(a_high),
        .b(b_high),
        .p(p_high)
    );
    
    karatsuba_submult #(4) low_mult (
        .a(a_low),
        .b(b_low),
        .p(p_low)
    );
    
    karatsuba_submult #(4) mid_mult (
        .a(sum_a[3:0]),
        .b(sum_b[3:0]),
        .p(p_mid)
    );
    
    // Calculate middle term
    assign p_mid_term = p_mid - p_high - p_low;
    
    // Combine results using Karatsuba algorithm
    always @(*) begin
        if (rst) begin
            y = 16'b0;  // Reset output to 0
        end else begin
            y = {p_high, 8'b0} + {p_mid_term, 4'b0} + p_low;
        end
    end
endmodule

// Submultiplier module for Karatsuba algorithm
module karatsuba_submult #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [2*WIDTH-1:0] p
);
    assign p = a * b;
endmodule