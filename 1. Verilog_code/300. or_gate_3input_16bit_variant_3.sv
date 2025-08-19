//SystemVerilog
// Top-level module for 3-input 16-bit OR operation
module or_gate_3input_16bit (
    input wire [15:0] a,
    input wire [15:0] b,
    input wire [15:0] c,
    output wire [15:0] y
);
    // Parameterized multi-input OR gate instance
    multi_input_or_gate #(
        .DATA_WIDTH(16),
        .NUM_INPUTS(3)
    ) multi_or_inst (
        .inputs({a, b, c}),
        .result(y)
    );
endmodule

// Parameterized multi-input OR gate module
module multi_input_or_gate #(
    parameter DATA_WIDTH = 16,
    parameter NUM_INPUTS = 3
)(
    input wire [DATA_WIDTH*NUM_INPUTS-1:0] inputs,
    output wire [DATA_WIDTH-1:0] result
);
    // Intermediate result for reduction operation
    wire [DATA_WIDTH-1:0] reduction_result;
    
    // Instance of bit-slice processor for OR reduction
    bit_slice_processor #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_INPUTS(NUM_INPUTS),
        .OPERATION("OR")
    ) bit_slice_inst (
        .data_in(inputs),
        .result(reduction_result)
    );
    
    assign result = reduction_result;
endmodule

// Bit-slice processor for various operations
module bit_slice_processor #(
    parameter DATA_WIDTH = 16,
    parameter NUM_INPUTS = 3,
    parameter OPERATION = "OR"  // Can be extended for AND, XOR, etc.
)(
    input wire [DATA_WIDTH*NUM_INPUTS-1:0] data_in,
    output wire [DATA_WIDTH-1:0] result
);
    // Process DATA_WIDTH bits in parallel
    genvar bit_idx;
    generate
        for (bit_idx = 0; bit_idx < DATA_WIDTH; bit_idx = bit_idx + 1) begin : bit_processor_gen
            // Instance of single-bit multi-input processor
            single_bit_processor #(
                .NUM_INPUTS(NUM_INPUTS),
                .OPERATION(OPERATION)
            ) bit_proc_inst (
                .bits_in(extract_bit_slice(data_in, bit_idx, NUM_INPUTS, DATA_WIDTH)),
                .result(result[bit_idx])
            );
        end
    endgenerate
    
    // Function to extract specific bit from all inputs
    function [NUM_INPUTS-1:0] extract_bit_slice;
        input [DATA_WIDTH*NUM_INPUTS-1:0] data;
        input integer bit_position;
        input integer num_inputs;
        input integer data_width;
        
        integer i;
        begin
            for (i = 0; i < num_inputs; i = i + 1) begin
                extract_bit_slice[i] = data[i*data_width + bit_position];
            end
        end
    endfunction
endmodule

// Single-bit multi-input processor module
module single_bit_processor #(
    parameter NUM_INPUTS = 3,
    parameter OPERATION = "OR"
)(
    input wire [NUM_INPUTS-1:0] bits_in,
    output wire result
);
    // Implement OR reduction for multiple inputs
    // Can be extended to support other operations
    generate
        if (OPERATION == "OR") begin : or_op
            assign result = |bits_in;  // Reduction OR operator
        end
        // Other operations can be added here
    endgenerate
endmodule