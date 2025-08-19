//SystemVerilog
module async_diff_filter #(
    parameter DATA_SIZE = 10
)(
    input [DATA_SIZE-1:0] current_sample,
    input [DATA_SIZE-1:0] prev_sample,
    output [DATA_SIZE:0] diff_out  // One bit wider to handle negative
);
    // Internal signals for carry-lookahead implementation
    wire [DATA_SIZE:0] extended_current;
    wire [DATA_SIZE:0] inverted_prev;
    wire [DATA_SIZE:0] twos_comp_prev;
    
    // Sign-extend current sample
    assign extended_current = {current_sample[DATA_SIZE-1], current_sample};
    
    // Invert prev_sample for two's complement
    assign inverted_prev = ~{prev_sample[DATA_SIZE-1], prev_sample};
    
    // Carry-lookahead adder implementation for two's complement calculation
    wire [DATA_SIZE:0] p, g; // Propagate and generate signals
    wire [DATA_SIZE+1:0] c;  // Carry signals (extra bit for carry-in)
    
    // Initialize carry-in for two's complement (adding 1)
    assign c[0] = 1'b1;
    
    // Generate propagate and generate signals
    assign p = inverted_prev | {(DATA_SIZE+1){1'b0}}; // Propagate = A | B
    assign g = inverted_prev & {(DATA_SIZE+1){1'b0}}; // Generate = A & B
    
    // Calculate carries using carry-lookahead logic
    genvar i;
    generate
        for (i = 0; i <= DATA_SIZE; i = i + 1) begin : carry_lookahead
            assign c[i+1] = g[i] | (p[i] & c[i]);
        end
    endgenerate
    
    // Calculate two's complement using propagate and carries
    assign twos_comp_prev = p ^ c[DATA_SIZE:0];
    
    // Carry-lookahead adder for final subtraction
    wire [DATA_SIZE:0] diff_p, diff_g; // Propagate and generate signals for difference
    wire [DATA_SIZE+1:0] diff_c;       // Carry signals for difference
    
    // Initialize carry-in for final addition
    assign diff_c[0] = 1'b0;
    
    // Generate propagate and generate signals for final addition
    assign diff_p = extended_current | twos_comp_prev;
    assign diff_g = extended_current & twos_comp_prev;
    
    // Calculate carries using carry-lookahead logic
    genvar j;
    generate
        for (j = 0; j <= DATA_SIZE; j = j + 1) begin : diff_carry_lookahead
            assign diff_c[j+1] = diff_g[j] | (diff_p[j] & diff_c[j]);
        end
    endgenerate
    
    // Calculate final difference
    assign diff_out = extended_current ^ twos_comp_prev ^ diff_c[DATA_SIZE:0];
endmodule