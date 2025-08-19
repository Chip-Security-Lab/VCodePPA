//SystemVerilog
module async_multi_rate_filter #(
    parameter W = 10
)(
    input [W-1:0] fast_in,
    input [W-1:0] slow_in,
    input [3:0] alpha,  // Blend factor 0-15
    output [W-1:0] filtered_out
);
    // Blend between fast and slow signals based on alpha
    wire [W+4-1:0] fast_scaled, slow_scaled;
    wire [3:0] alpha_complement;
    
    assign alpha_complement = 16 - alpha;
    
    // Use Karatsuba multiplication instead of direct multiplication
    karatsuba_mult #(.W_A(W), .W_B(4)) fast_mult (
        .a(fast_in),
        .b(alpha),
        .product(fast_scaled)
    );
    
    karatsuba_mult #(.W_A(W), .W_B(4)) slow_mult (
        .a(slow_in),
        .b(alpha_complement),
        .product(slow_scaled)
    );
    
    assign filtered_out = (fast_scaled + slow_scaled) >> 4;
endmodule

module karatsuba_mult #(
    parameter W_A = 10,
    parameter W_B = 4
)(
    input [W_A-1:0] a,
    input [W_B-1:0] b,
    output [W_A+W_B-1:0] product
);
    generate
        if (W_B <= 2) begin
            // Base case: use standard multiplication for small width
            assign product = a * b;
        end else begin
            // Split inputs for Karatsuba algorithm
            localparam SPLIT_B = W_B / 2;
            
            wire [SPLIT_B-1:0] b_low;
            wire [W_B-SPLIT_B-1:0] b_high;
            
            // Split b into high and low parts
            assign b_low = b[SPLIT_B-1:0];
            assign b_high = b[W_B-1:SPLIT_B];
            
            // Compute products recursively
            wire [W_A+SPLIT_B-1:0] p_low;       // a * b_low
            wire [W_A+W_B-SPLIT_B-1:0] p_high;  // a * b_high
            wire [W_A+W_B-1:0] p_high_shifted;  // (a * b_high) << SPLIT_B
            
            karatsuba_mult #(.W_A(W_A), .W_B(SPLIT_B)) low_mult (
                .a(a),
                .b(b_low),
                .product(p_low)
            );
            
            karatsuba_mult #(.W_A(W_A), .W_B(W_B-SPLIT_B)) high_mult (
                .a(a),
                .b(b_high),
                .product(p_high)
            );
            
            // Combine results using shift and addition
            assign p_high_shifted = p_high << SPLIT_B;
            assign product = p_low + p_high_shifted;
        end
    endgenerate
endmodule