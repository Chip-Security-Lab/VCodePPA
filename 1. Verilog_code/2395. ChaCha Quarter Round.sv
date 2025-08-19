module chacha_quarter_round (
    input wire [31:0] a_in, b_in, c_in, d_in,
    output wire [31:0] a_out, b_out, c_out, d_out
);
    // Simplified ChaCha20 quarter round
    wire [31:0] a1, b1, c1, d1;
    
    assign a1 = a_in + b_in;
    assign d1 = d_in ^ a1;
    assign d_out = {d1[15:0], d1[31:16]}; // Rotate left 16
    
    assign c1 = c_in + d_out;
    assign b1 = b_in ^ c1;
    assign b_out = {b1[19:0], b1[31:20]}; // Rotate left 12
    
    assign a_out = a1 + b_out;
    assign c_out = c1;
endmodule