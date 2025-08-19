//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: demux_onehot_top.v
// Description: Top level module for one-hot demultiplexer with subtractor
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module Demux_OneHot #(
    parameter DW = 16,  // Data width
    parameter N  = 4    // Number of output channels
)(
    input  [DW-1:0]       din,   // Input data
    input  [N-1:0]        sel,   // One-hot selection
    output [N-1:0][DW-1:0] dout,  // Output data channels
    
    // 8-bit subtractor interface
    input  [7:0] sub_a,         // 8-bit minuend
    input  [7:0] sub_b,         // 8-bit subtrahend
    output [7:0] sub_result,    // 8-bit difference
    output       sub_borrow     // Borrow out flag
);

    // Instantiate demux channels
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : demux_channel_inst
            Demux_Channel #(
                .DW(DW)
            ) channel (
                .din      (din),
                .sel      (sel[i]),
                .dout     (dout[i])
            );
        end
    endgenerate
    
    // Instantiate conditional sum subtractor
    ConditionalSumSubtractor #(
        .WIDTH(8)
    ) subtractor (
        .a(sub_a),
        .b(sub_b),
        .diff(sub_result),
        .borrow_out(sub_borrow)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: demux_channel.v
// Description: Single channel for one-hot demultiplexer
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module Demux_Channel #(
    parameter DW = 16  // Data width
)(
    input  [DW-1:0] din,   // Input data
    input           sel,   // Channel select
    output [DW-1:0] dout   // Output data
);

    // Output control logic
    assign dout = sel ? din : {DW{1'b0}};

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: conditional_sum_subtractor.v
// Description: 8-bit subtractor using conditional sum algorithm
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module ConditionalSumSubtractor #(
    parameter WIDTH = 8  // Width of operands
)(
    input  [WIDTH-1:0] a,           // Minuend
    input  [WIDTH-1:0] b,           // Subtrahend
    output [WIDTH-1:0] diff,        // Difference
    output             borrow_out   // Borrow out flag
);

    // Internal signals for conditional borrow paths
    wire [WIDTH:0] borrow_chain;    // Include extra bit for final borrow out
    wire [WIDTH-1:0] diff_with_borrow_0; // Result assuming incoming borrow = 0
    wire [WIDTH-1:0] diff_with_borrow_1; // Result assuming incoming borrow = 1
    
    // Set initial borrow to 0
    assign borrow_chain[0] = 1'b0;
    
    // Generate conditional results for each bit position
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : sub_bit
            // Case 1: Assuming incoming borrow = 0
            assign diff_with_borrow_0[i] = a[i] ^ b[i];
            wire borrow_gen_0 = (~a[i]) & b[i];
            
            // Case 2: Assuming incoming borrow = 1
            assign diff_with_borrow_1[i] = a[i] ^ b[i] ^ 1'b1;
            wire borrow_gen_1 = (~a[i]) | b[i];
            
            // Select appropriate borrow for this bit based on incoming borrow
            assign borrow_chain[i+1] = borrow_chain[i] ? borrow_gen_1 : borrow_gen_0;
            
            // Select the correct difference bit based on the incoming borrow
            assign diff[i] = borrow_chain[i] ? diff_with_borrow_1[i] : diff_with_borrow_0[i];
        end
    endgenerate
    
    // Final borrow out
    assign borrow_out = borrow_chain[WIDTH];
    
endmodule