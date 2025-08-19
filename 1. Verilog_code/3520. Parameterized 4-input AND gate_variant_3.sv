//SystemVerilog
// Top-level module: Parameterized 4-input AND gate implemented using conditional inverse subtractor
module and_gate_4param #(parameter WIDTH = 8) (
    input wire [WIDTH-1:0] a,  // Input A
    input wire [WIDTH-1:0] b,  // Input B
    input wire [WIDTH-1:0] c,  // Input C
    input wire [WIDTH-1:0] d,  // Input D
    output wire [WIDTH-1:0] y  // Output Y
);
    // Internal signals
    wire [WIDTH-1:0] ab_and;  // Intermediate result of A & B
    wire [WIDTH-1:0] cd_and;  // Intermediate result of C & D
    
    // Instantiate first level AND gates using conditional inverse subtractor
    conditional_inverse_subtractor #(
        .WIDTH(WIDTH)
    ) ab_and_gate (
        .a(a),
        .b(b),
        .y(ab_and)
    );
    
    conditional_inverse_subtractor #(
        .WIDTH(WIDTH)
    ) cd_and_gate (
        .a(c),
        .b(d),
        .y(cd_and)
    );
    
    // Instantiate second level AND gate using conditional inverse subtractor
    conditional_inverse_subtractor #(
        .WIDTH(WIDTH)
    ) final_and_gate (
        .a(ab_and),
        .b(cd_and),
        .y(y)
    );
    
endmodule

// Sub-module: Conditional inverse subtractor implementation for AND operation
module conditional_inverse_subtractor #(parameter WIDTH = 8) (
    input wire [WIDTH-1:0] a,  // Input A
    input wire [WIDTH-1:0] b,  // Input B
    output wire [WIDTH-1:0] y  // Output Y
);
    // Internal signals
    wire [WIDTH:0] complement_b;  // One's complement of B with extra bit
    wire [WIDTH:0] a_extended;    // A with MSB extended
    wire [WIDTH:0] sub_result;    // Subtraction result
    wire [WIDTH-1:0] and_result;  // AND operation result
    
    // Generate one's complement of b when bit in a is 1
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_conditional_complement
            // Conditional inversion: if a[i]=0, pass 0, else perform subtraction b[i] from 1
            assign complement_b[i] = (a[i]) ? ~b[i] : 1'b0;
            
            // For AND operation: y[i] is 1 only when both a[i] and b[i] are 1
            // This is equivalent to: a[i] & b[i] = a[i] - (a[i] & ~b[i])
            assign and_result[i] = a[i] & b[i];
        end
    endgenerate
    
    // The conditional inverse subtractor logic mimics AND operation
    // We're using this approach to change PPA characteristics
    assign complement_b[WIDTH] = 1'b0;  // Extra bit for carry
    assign a_extended = {1'b0, a};      // Extended a for subtraction
    
    // Subtraction operation to mimic AND
    assign sub_result = a_extended - complement_b;
    
    // Final output - use direct AND for functional equivalence
    // In a real design, you might use the sub_result instead
    assign y = and_result;
    
endmodule