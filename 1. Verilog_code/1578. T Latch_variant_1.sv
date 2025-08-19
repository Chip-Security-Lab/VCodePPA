//SystemVerilog
module t_latch (
    input wire t,        // Toggle input
    input wire enable,
    output reg q
);
    reg next_q;
    
    // Combinational logic for next state
    always @* begin
        if (enable && t) begin
            next_q = ~q;
        end else begin
            next_q = q;
        end
    end
    
    // Sequential logic for state update
    always @(posedge enable) begin
        q <= next_q;
    end
endmodule

module karatsuba_multiplier #(
    parameter WIDTH = 8
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [2*WIDTH-1:0] result
);

    // Base case for 1-bit multiplication
    generate
        if (WIDTH == 1) begin
            assign result = a & b;
        end
        else begin
            localparam HALF_WIDTH = WIDTH/2;
            
            wire [HALF_WIDTH-1:0] a_high = a[WIDTH-1:HALF_WIDTH];
            wire [HALF_WIDTH-1:0] a_low = a[HALF_WIDTH-1:0];
            wire [HALF_WIDTH-1:0] b_high = b[WIDTH-1:HALF_WIDTH];
            wire [HALF_WIDTH-1:0] b_low = b[HALF_WIDTH-1:0];
            
            wire [2*HALF_WIDTH-1:0] z0, z1, z2;
            wire [2*HALF_WIDTH-1:0] sum_a, sum_b;
            
            // Compute z0 = a_low * b_low
            karatsuba_multiplier #(HALF_WIDTH) mult_z0 (
                .a(a_low),
                .b(b_low),
                .result(z0)
            );
            
            // Compute z1 = (a_high + a_low) * (b_high + b_low)
            assign sum_a = a_high + a_low;
            assign sum_b = b_high + b_low;
            karatsuba_multiplier #(HALF_WIDTH) mult_z1 (
                .a(sum_a),
                .b(sum_b),
                .result(z1)
            );
            
            // Compute z2 = a_high * b_high
            karatsuba_multiplier #(HALF_WIDTH) mult_z2 (
                .a(a_high),
                .b(b_high),
                .result(z2)
            );
            
            // Final result calculation
            assign result = (z2 << WIDTH) + ((z1 - z2 - z0) << HALF_WIDTH) + z0;
        end
    endgenerate
endmodule