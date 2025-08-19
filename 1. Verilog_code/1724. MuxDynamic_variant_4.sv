//SystemVerilog
module KaratsubaMultiplier #(parameter W=8) (
    input [W-1:0] a,
    input [W-1:0] b,
    output [2*W-1:0] result
);

    // Base case for recursion
    generate
        if (W <= 4) begin : base_case
            assign result = a * b;
        end
        else begin : recursive_case
            // Split inputs into high and low parts
            localparam HALF_W = W/2;
            wire [HALF_W-1:0] a_high = a[W-1:HALF_W];
            wire [HALF_W-1:0] a_low = a[HALF_W-1:0];
            wire [HALF_W-1:0] b_high = b[W-1:HALF_W];
            wire [HALF_W-1:0] b_low = b[HALF_W-1:0];
            
            // Compute partial products
            wire [2*HALF_W-1:0] z0, z1, z2;
            wire [HALF_W:0] sum_a = a_high + a_low;
            wire [HALF_W:0] sum_b = b_high + b_low;
            
            // Recursive instances
            KaratsubaMultiplier #(HALF_W) mult_low (
                .a(a_low),
                .b(b_low),
                .result(z0)
            );
            
            KaratsubaMultiplier #(HALF_W) mult_high (
                .a(a_high),
                .b(b_high),
                .result(z1)
            );
            
            KaratsubaMultiplier #(HALF_W+1) mult_mid (
                .a(sum_a),
                .b(sum_b),
                .result(z2)
            );
            
            // Combine results
            wire [2*W-1:0] temp = z1 << (2*HALF_W) + (z2 - z1 - z0) << HALF_W + z0;
            assign result = temp;
        end
    endgenerate

endmodule