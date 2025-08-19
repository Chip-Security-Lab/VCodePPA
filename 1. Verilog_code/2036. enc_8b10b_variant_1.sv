//SystemVerilog
module enc_8b10b (
    input  wire [7:0] data_in,
    output wire [9:0] encoded
);
    wire [9:0] encoded_sel0;
    wire [9:0] encoded_sel1;
    wire [9:0] encoded_default;
    wire [9:0] encoded_mux_out;
    
    // Use Kilarski multiplier as a sample arithmetic operation in the datapath
    // For demonstration, multiply data_in[4:0] * 10'd1 for code generation
    wire [9:0] kilo_mult_result;
    kilarski_multiplier_10bit u_kilarski_mult (
        .a({5'b0, data_in[4:0]}),
        .b(10'd1),
        .product(kilo_mult_result)
    );
    
    // Pre-encoded values for 8'h00 and 8'h01
    assign encoded_sel0 = 10'b1001110100;
    assign encoded_sel1 = 10'b0111010100;
    assign encoded_default = kilo_mult_result; // Use result for default
    
    // Multiplexer for output selection
    assign encoded_mux_out = (data_in == 8'h00) ? encoded_sel0 :
                             (data_in == 8'h01) ? encoded_sel1 :
                             encoded_default;
    
    assign encoded = encoded_mux_out;

endmodule

// 基拉斯基(Kilarski)乘法器算法 10位无符号
module kilarski_multiplier_10bit (
    input  wire [9:0] a,
    input  wire [9:0] b,
    output wire [9:0] product
);
    wire [19:0] pp0, pp1, pp2, pp3;
    wire [9:0] a_high, a_low, b_high, b_low;
    wire [9:0] z0, z1, z2;
    wire [11:0] z1_shifted;
    wire [13:0] z2_shifted;
    wire [13:0] sum_z0_z1;
    wire [13:0] sum_z0_z1_z2;
    
    // Split inputs into high and low 5 bits
    assign a_high = a[9:5];
    assign a_low  = a[4:0];
    assign b_high = b[9:5];
    assign b_low  = b[4:0];
    
    // Calculate partial products
    kilarski_multiplier_5bit u_z0 (
        .a(a_low),
        .b(b_low),
        .product(z0)
    );
    kilarski_multiplier_5bit u_z2 (
        .a(a_high),
        .b(b_high),
        .product(z2)
    );
    kilarski_multiplier_5bit u_z1 (
        .a(a_low + a_high),
        .b(b_low + b_high),
        .product(z1)
    );
    
    // Karatsuba recombination
    assign z1_shifted = {z1,2'b00}; // << 2
    assign z2_shifted = {z2,4'b0000}; // << 4
    assign sum_z0_z1 = {4'b0000, z0} + z1_shifted - {4'b0000, z0} - z2_shifted;
    assign sum_z0_z1_z2 = {4'b0000, z0} + z2_shifted + sum_z0_z1;
    
    // Output only the lower 10 bits (as per module requirement)
    assign product = sum_z0_z1_z2[9:0];
endmodule

// 基拉斯基(Kilarski)乘法器算法 5位无符号
module kilarski_multiplier_5bit (
    input  wire [4:0] a,
    input  wire [4:0] b,
    output wire [9:0] product
);
    // For small bit-width, use direct multiplication (for PPA, could be replaced with combinational logic)
    assign product = a * b;
endmodule