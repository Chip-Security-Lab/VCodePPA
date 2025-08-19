//SystemVerilog
module multiplier_8bit (
    input clk,
    input rst_n,
    input valid,
    output ready,
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] product,
    output reg valid_out,
    input ready_out
);

    // Internal signals
    reg [7:0] a_reg, b_reg;
    reg [15:0] product_reg;
    reg busy;
    reg valid_out_reg;
    
    // Wallace tree multiplier implementation
    wire [7:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7;
    wire [8:0] sum1, carry1;
    wire [9:0] sum2, carry2;
    wire [10:0] sum3, carry3;
    wire [10:0] sum4, carry4;
    wire [11:0] sum5, carry5;
    wire [11:0] final_sum;
    wire [12:0] final_carry;
    
    // Generate partial products
    assign pp0 = {8{a_reg[0]}} & b_reg;
    assign pp1 = {8{a_reg[1]}} & b_reg;
    assign pp2 = {8{a_reg[2]}} & b_reg;
    assign pp3 = {8{a_reg[3]}} & b_reg;
    assign pp4 = {8{a_reg[4]}} & b_reg;
    assign pp5 = {8{a_reg[5]}} & b_reg;
    assign pp6 = {8{a_reg[6]}} & b_reg;
    assign pp7 = {8{a_reg[7]}} & b_reg;
    
    // Wallace tree implementation
    compressor_3to2 comp1 (
        .a({1'b0, pp0}),
        .b({pp1, 1'b0}),
        .c({pp2, 2'b0}),
        .sum(sum1),
        .carry(carry1)
    );
    
    compressor_3to2 comp2 (
        .a({pp3, 3'b0}),
        .b({pp4, 4'b0}),
        .c({pp5, 5'b0}),
        .sum(sum2),
        .carry(carry2)
    );
    
    compressor_3to2 comp3 (
        .a({pp6, 6'b0}),
        .b({pp7, 7'b0}),
        .c(9'b0),
        .sum(sum3),
        .carry(carry3)
    );
    
    compressor_3to2 comp4 (
        .a(sum1),
        .b({carry1, 1'b0}),
        .c(sum2),
        .sum(sum4),
        .carry(carry4)
    );
    
    compressor_3to2 comp5 (
        .a({carry2, 2'b0}),
        .b(sum3),
        .c({carry3, 3'b0}),
        .sum(sum5),
        .carry(carry5)
    );
    
    compressor_3to2 comp6 (
        .a(sum4),
        .b({carry4, 1'b0}),
        .c(sum5),
        .sum(final_sum),
        .carry(final_carry)
    );
    
    // Valid-Ready handshake logic
    assign ready = ~busy;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            valid_out_reg <= 1'b0;
            product_reg <= 16'b0;
            a_reg <= 8'b0;
            b_reg <= 8'b0;
        end else begin
            if (valid && ready) begin
                a_reg <= a;
                b_reg <= b;
                busy <= 1'b1;
            end
            
            if (busy) begin
                product_reg <= final_sum + {final_carry, 1'b0};
                valid_out_reg <= 1'b1;
                busy <= 1'b0;
            end
            
            if (valid_out_reg && ready_out) begin
                valid_out_reg <= 1'b0;
            end
        end
    end
    
    assign product = product_reg;
    assign valid_out = valid_out_reg;
    
endmodule

module compressor_3to2 (
    input [8:0] a,
    input [8:0] b,
    input [8:0] c,
    output [8:0] sum,
    output [8:0] carry
);
    genvar i;
    generate
        for (i = 0; i < 9; i = i + 1) begin : compressors
            full_adder fa (
                .a(a[i]),
                .b(b[i]),
                .c(c[i]),
                .sum(sum[i]),
                .cout(carry[i])
            );
        end
    endgenerate
endmodule

module full_adder (
    input a,
    input b,
    input c,
    output sum,
    output cout
);
    wire s1, c1, c2;
    
    half_adder ha1 (
        .a(a),
        .b(b),
        .sum(s1),
        .cout(c1)
    );
    
    half_adder ha2 (
        .a(s1),
        .b(c),
        .sum(sum),
        .cout(c2)
    );
    
    assign cout = c1 | c2;
endmodule

module half_adder (
    input a,
    input b,
    output sum,
    output cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule