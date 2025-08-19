//SystemVerilog
// Top level module - Two's complement subtractor implementation
module loop_multi_xnor #(
    parameter LENGTH = 8
)(
    input wire [LENGTH-1:0] input_vecA, input_vecB,
    output wire [LENGTH-1:0] output_vec
);
    // Internal signals
    wire [LENGTH-1:0] complement_B;
    wire [LENGTH-1:0] sub_result;
    wire carry_out;
    
    // Instantiate two's complement generator for input_vecB
    twos_complement_gen #(
        .WIDTH(LENGTH)
    ) comp_gen (
        .data_in(input_vecB),
        .data_out(complement_B)
    );
    
    // Instantiate binary adder (A + (-B))
    binary_adder #(
        .WIDTH(LENGTH)
    ) adder_stage (
        .a(input_vecA),
        .b(complement_B),
        .cin(1'b0),
        .sum(sub_result),
        .cout(carry_out)
    );
    
    // XNOR functionality preserved through bitwise NOT of subtraction result
    assign output_vec = ~sub_result;
    
endmodule

// Submodule for two's complement generation
module twos_complement_gen #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    // Two's complement: invert and add 1
    wire [WIDTH-1:0] inverted_data;
    wire [WIDTH-1:0] partial_result;
    wire [WIDTH:0] carry_chain;
    
    // Step 1: Invert all bits
    assign inverted_data = ~data_in;
    
    // Step 2: Add 1 with explicit carry chain
    assign carry_chain[0] = 1'b1; // Initial carry-in of 1
    
    genvar j;
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin : complement_gen
            assign partial_result[j] = inverted_data[j] ^ carry_chain[j];
            assign carry_chain[j+1] = inverted_data[j] & carry_chain[j];
        end
    endgenerate
    
    // Final output assignment
    assign data_out = partial_result;
endmodule

// Submodule for binary addition with improved carry logic
module binary_adder #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cin,
    output wire [WIDTH-1:0] sum,
    output wire cout
);
    // Internal signals for carry calculation
    wire [WIDTH:0] carry;
    wire [WIDTH-1:0] gen;  // Generate signal
    wire [WIDTH-1:0] prop; // Propagate signal
    
    // Initial carry input
    assign carry[0] = cin;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : adder_stage
            // Compute generate and propagate signals
            assign gen[i] = a[i] & b[i];
            assign prop[i] = a[i] | b[i];
            
            // Sum calculation using XOR
            assign sum[i] = a[i] ^ b[i] ^ carry[i];
            
            // Carry calculation with simplified conditional logic
            wire carry_gen;    // Carry generated at this stage
            wire carry_prop;   // Carry propagated from previous stage
            
            assign carry_gen = gen[i];
            assign carry_prop = prop[i] & carry[i];
            assign carry[i+1] = carry_gen | carry_prop;
        end
    endgenerate
    
    // Final carry output
    assign cout = carry[WIDTH];
endmodule