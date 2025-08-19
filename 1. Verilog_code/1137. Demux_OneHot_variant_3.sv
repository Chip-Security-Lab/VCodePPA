//SystemVerilog
module Demux_OneHot #(parameter DW=16, N=4) (
    input [DW-1:0] din,
    input [N-1:0] sel,
    input [7:0] a_in,
    input [7:0] b_in,
    input c_in,
    output [N-1:0][DW-1:0] dout,
    output [7:0] sum,
    output c_out
);
    // Optimized demux functionality using direct bit-wise connection
    // Reduces logic depth by avoiding multi-bit conditional gates
    generate 
        genvar i;
        for(i=0; i<N; i=i+1) begin : demux_gen
            assign dout[i] = {DW{sel[i]}} & din;
        end
    endgenerate
    
    // Optimized 8-bit Carry-Skip Adder implementation
    wire [7:0] p; // Propagate signals
    wire [7:0] g; // Generate signals
    wire [2:0] block_p; // Block propagate signals
    wire [8:0] c; // Carry signals
    
    // Generate propagate and generate signals - no change needed
    assign p = a_in ^ b_in;
    assign g = a_in & b_in;
    
    // Input carry
    assign c[0] = c_in;
    
    // Optimized block propagate signals computation
    assign block_p[0] = p[0] & p[1];
    assign block_p[1] = p[2] & p[3];
    assign block_p[2] = p[4] & p[5];
    
    // Simplified carry computation for first two bits
    assign c[1] = g[0] | (p[0] & c[0]);
    // Using distributive law to simplify: g[1] | (p[1] & (g[0] | (p[0] & c[0]))) = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0])
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    
    // Block 0 skip logic - simplified using multiplexer concept
    assign c[3] = block_p[0] ? c[1] : (g[2] | (p[2] & c[2]));
    // Optimized carry generation
    assign c[4] = g[3] | (p[3] & c[3]);
    
    // Block 1 skip logic - simplified
    assign c[5] = block_p[1] ? c[3] : (g[4] | (p[4] & c[4]));
    // Optimized carry generation
    assign c[6] = g[5] | (p[5] & c[5]);
    
    // Block 2 skip logic - simplified
    assign c[7] = block_p[2] ? c[5] : (g[6] | (p[6] & c[6]));
    // Final carry calculation
    assign c[8] = g[7] | (p[7] & c[7]);
    
    // Sum computation - XOR is already optimal
    assign sum = p ^ c[7:0];
    
    // Final carry out
    assign c_out = c[8];
    
endmodule