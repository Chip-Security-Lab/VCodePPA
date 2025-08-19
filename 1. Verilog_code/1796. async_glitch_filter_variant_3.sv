//SystemVerilog
module async_glitch_filter #(
    parameter GLITCH_THRESHOLD = 3
)(
    input [GLITCH_THRESHOLD-1:0] samples,
    output filtered_out
);
    // Generate and Propagate signals for CLA
    wire [GLITCH_THRESHOLD-1:0] G, P;
    wire [GLITCH_THRESHOLD:0] C;
    
    // Count implementation using Carry Look-Ahead Adder
    genvar i;
    generate
        // Initialize carry-in to zero
        assign C[0] = 1'b0;
        
        for (i = 0; i < GLITCH_THRESHOLD; i = i + 1) begin : cla_logic
            // Generate and Propagate signals
            assign G[i] = samples[i];  // Generate if input bit is 1
            assign P[i] = 1'b1;        // Always propagate for counter
            
            // Carry look-ahead logic
            assign C[i+1] = G[i] | (P[i] & C[i]);
        end
    endgenerate
    
    // Sum calculation for counting ones
    wire [GLITCH_THRESHOLD-1:0] sum;
    generate
        for (i = 0; i < GLITCH_THRESHOLD; i = i + 1) begin : sum_logic
            assign sum[i] = P[i] ^ C[i];
        end
    endgenerate
    
    // Final count is the number of 1's in samples
    wire [GLITCH_THRESHOLD:0] final_count;
    assign final_count = {1'b0, sum} + {1'b0, C[GLITCH_THRESHOLD]};
    
    // Majority voting decision
    assign filtered_out = (final_count > GLITCH_THRESHOLD/2);
endmodule