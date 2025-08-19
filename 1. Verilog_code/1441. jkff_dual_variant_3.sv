//SystemVerilog
module jkff_with_multiplier (
    input clk, rstn,
    input j, k,
    input [7:0] a, b,
    output reg q,
    output [15:0] product
);
    // JK flip-flop logic
    reg q_next;
    wire jk_set, jk_reset, jk_toggle, jk_hold;
    
    // Pre-compute JK decision logic
    assign jk_hold = ({j,k} == 2'b00);
    assign jk_set = ({j,k} == 2'b10);
    assign jk_reset = ({j,k} == 2'b01);
    assign jk_toggle = ({j,k} == 2'b11);
    
    // Compute next state
    always @(*) begin
        if (jk_hold) q_next = q;
        else if (jk_set) q_next = 1'b1;
        else if (jk_reset) q_next = 1'b0;
        else q_next = ~q;
    end
    
    // Register output
    always @(posedge clk or negedge rstn) begin
        if (!rstn) 
            q <= 1'b0;
        else
            q <= q_next;
    end

    // Instantiate recursive Karatsuba multiplier
    karatsuba_multiplier_8bit kmult (
        .a(a),
        .b(b),
        .product(product)
    );
endmodule

// Recursive Karatsuba multiplier for 8-bit operands
module karatsuba_multiplier_8bit (
    input [7:0] a,
    input [7:0] b,
    output [15:0] product
);
    wire [15:0] direct_product;
    
    // Call the recursive implementation
    karatsuba_recursive #(8) kmult_core (
        .a(a),
        .b(b),
        .product(direct_product)
    );
    
    assign product = direct_product;
endmodule

// Parameterized recursive Karatsuba multiplier
module karatsuba_recursive #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [2*WIDTH-1:0] product
);
    generate
        if (WIDTH <= 4) begin : BASE_CASE
            // Base case: use standard multiplication for small operands
            assign product = a * b;
        end
        else begin : RECURSIVE_CASE
            localparam HALF_WIDTH = WIDTH / 2;
            
            // Split inputs into high and low parts
            wire [HALF_WIDTH-1:0] a_low, b_low;
            wire [HALF_WIDTH-1:0] a_high, b_high;
            
            assign a_low = a[HALF_WIDTH-1:0];
            assign a_high = a[WIDTH-1:HALF_WIDTH];
            assign b_low = b[HALF_WIDTH-1:0];
            assign b_high = b[WIDTH-1:HALF_WIDTH];
            
            // Intermediate products
            wire [2*HALF_WIDTH-1:0] p_high, p_low, p_mid;
            wire [2*HALF_WIDTH-1:0] sum_a, sum_b;
            wire [2*HALF_WIDTH:0] p_mid_adj;  // Extra bit for potential carry
            
            // a_high * b_high
            karatsuba_recursive #(HALF_WIDTH) high_mult (
                .a(a_high),
                .b(b_high),
                .product(p_high)
            );
            
            // a_low * b_low
            karatsuba_recursive #(HALF_WIDTH) low_mult (
                .a(a_low),
                .b(b_low),
                .product(p_low)
            );
            
            // (a_high + a_low) * (b_high + b_low)
            assign sum_a = a_high + a_low;
            assign sum_b = b_high + b_low;
            
            karatsuba_recursive #(HALF_WIDTH) mid_mult (
                .a(sum_a[HALF_WIDTH-1:0]),
                .b(sum_b[HALF_WIDTH-1:0]),
                .product(p_mid)
            );
            
            // Adjust middle term: p_mid - p_high - p_low
            assign p_mid_adj = p_mid - p_high - p_low;
            
            // Combine results: p_high * 2^WIDTH + (p_mid - p_high - p_low) * 2^(WIDTH/2) + p_low
            assign product = {p_high, {HALF_WIDTH{1'b0}}} + 
                            {{{HALF_WIDTH{1'b0}}, p_mid_adj[2*HALF_WIDTH-1:0]}, {HALF_WIDTH{1'b0}}} + 
                            {{WIDTH{1'b0}}, p_low};
        end
    endgenerate
endmodule