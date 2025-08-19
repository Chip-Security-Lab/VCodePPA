//SystemVerilog
// Top-level module - 8-bit borrowing subtractor
module nand2_5 (
    input  wire [7:0] A,
    input  wire [7:0] B,
    output wire [7:0] Y
);
    // Internal signals for borrowing subtractor implementation
    wire [7:0] diff;
    wire [8:0] borrow;
    
    // Initialize first borrow bit to 0
    assign borrow[0] = 1'b0;
    
    // Instantiate the full subtractor module
    borrow_subtractor u_sub (
        .a_in(A),
        .b_in(B),
        .borrow_in(borrow[0]),
        .diff_out(diff),
        .borrow_out(borrow[8:1])
    );
    
    // Output is the difference result
    assign Y = diff;
    
endmodule

// 8-bit borrowing subtractor implementation
module borrow_subtractor #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] a_in,
    input  wire [WIDTH-1:0] b_in,
    input  wire borrow_in,
    output wire [WIDTH-1:0] diff_out,
    output wire [WIDTH:0] borrow_out
);
    // Calculate difference and borrow for each bit position
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : bit_sub
            assign diff_out[i] = a_in[i] ^ b_in[i] ^ borrow_out[i];
            assign borrow_out[i+1] = (~a_in[i] & b_in[i]) | (~a_in[i] & borrow_out[i]) | (b_in[i] & borrow_out[i]);
        end
    endgenerate
    
    // First borrow bit comes from input
    assign borrow_out[0] = borrow_in;
    
endmodule