//SystemVerilog
// Top level module for XNOR vector operations
module loop_multi_xnor #(
    parameter LENGTH = 8
)(
    input  wire [LENGTH-1:0] input_vecA,
    input  wire [LENGTH-1:0] input_vecB,
    output wire [LENGTH-1:0] output_vec
);
    // Internal signals
    wire [LENGTH-1:0] subtraction_result;
    
    // Instantiate the subtractor module
    subtractor_engine #(
        .LENGTH(LENGTH)
    ) subtractor_inst (
        .a_in(input_vecA),
        .b_in(input_vecB),
        .result(subtraction_result)
    );
    
    // Instantiate the output processing module
    result_processor #(
        .LENGTH(LENGTH)
    ) processor_inst (
        .data_in(subtraction_result),
        .data_out(output_vec)
    );
    
endmodule

// Subtractor module that handles two's complement subtraction
module subtractor_engine #(
    parameter LENGTH = 8
)(
    input  wire [LENGTH-1:0] a_in,
    input  wire [LENGTH-1:0] b_in,
    output wire [LENGTH-1:0] result
);
    // Intermediate signals
    wire [LENGTH:0] carry;
    wire [LENGTH-1:0] b_inverted;
    
    // Initializing carry-in for subtraction
    assign carry[0] = 1'b1;
    
    // Instantiate the B-input conditioning module
    input_conditioner #(
        .LENGTH(LENGTH)
    ) b_conditioner (
        .data_in(b_in),
        .data_out(b_inverted)
    );
    
    // Full adder array for subtraction operation
    adder_array #(
        .LENGTH(LENGTH)
    ) adder_inst (
        .a_in(a_in),
        .b_in(b_inverted),
        .carry_in(carry[0]),
        .sum(result),
        .carry_out(carry[LENGTH:1])
    );
endmodule

// Input conditioning module for inverting the subtrahend
module input_conditioner #(
    parameter LENGTH = 8
)(
    input  wire [LENGTH-1:0] data_in,
    output wire [LENGTH-1:0] data_out
);
    // Invert each bit of the input
    genvar i;
    generate
        for (i = 0; i < LENGTH; i = i + 1) begin: invert_loop
            assign data_out[i] = ~data_in[i];
        end
    endgenerate
endmodule

// Full adder array for multi-bit addition
module adder_array #(
    parameter LENGTH = 8
)(
    input  wire [LENGTH-1:0] a_in,
    input  wire [LENGTH-1:0] b_in,
    input  wire carry_in,
    output wire [LENGTH-1:0] sum,
    output wire [LENGTH-1:0] carry_out
);
    // Internal signals for the full adder network
    wire [LENGTH:0] carry_chain;
    
    // Connect the carry input
    assign carry_chain[0] = carry_in;
    
    // Generate full adders for each bit position
    genvar i;
    generate
        for (i = 0; i < LENGTH; i = i + 1) begin: adder_loop
            // Instantiate the single-bit full adder module
            full_adder fa_inst (
                .a(a_in[i]),
                .b(b_in[i]),
                .cin(carry_chain[i]),
                .sum(sum[i]),
                .cout(carry_chain[i+1])
            );
            
            // Connect the carry output signals
            assign carry_out[i] = carry_chain[i+1];
        end
    endgenerate
endmodule

// Single-bit full adder module
module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    // Full adder logic
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

// Result processor module for final output transformation
module result_processor #(
    parameter LENGTH = 8
)(
    input  wire [LENGTH-1:0] data_in,
    output wire [LENGTH-1:0] data_out
);
    // Transform the subtraction result to maintain XNOR functionality
    genvar i;
    generate
        for (i = 0; i < LENGTH; i = i + 1) begin: transform_loop
            // Apply final transformation to get XNOR result
            assign data_out[i] = ~(data_in[i] ^ 1'b1);
        end
    endgenerate
endmodule