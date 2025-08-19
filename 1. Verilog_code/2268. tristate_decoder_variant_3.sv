//SystemVerilog
// Top-level module
module tristate_decoder(
    input [1:0] addr,
    input enable,
    output [3:0] select,
    // Adding inputs/outputs for Wallace multiplier
    input [3:0] multiplier_a,
    input [3:0] multiplier_b,
    output [7:0] product
);
    // Internal signals
    wire [3:0] decoded_output;
    
    // Instantiate address decoder submodule
    addr_decoder u_addr_decoder (
        .addr(addr),
        .decoded_output(decoded_output)
    );
    
    // Instantiate tristate buffer controller submodule
    tristate_controller u_tristate_controller (
        .enable(enable),
        .decoded_input(decoded_output),
        .select(select)
    );
    
    // Instantiate Wallace tree multiplier
    wallace_multiplier u_wallace_multiplier (
        .a(multiplier_a),
        .b(multiplier_b),
        .product(product)
    );
endmodule

// Address decoder submodule - converts binary address to one-hot encoding
module addr_decoder(
    input [1:0] addr,
    output reg [3:0] decoded_output
);
    // One-hot address decoding logic
    always @(*) begin
        decoded_output = 4'b0000;
        case (addr)
            2'b00: decoded_output = 4'b0001;
            2'b01: decoded_output = 4'b0010;
            2'b10: decoded_output = 4'b0100;
            2'b11: decoded_output = 4'b1000;
            default: decoded_output = 4'b0000;
        endcase
    end
endmodule

// Tristate buffer controller submodule
module tristate_controller(
    input enable,
    input [3:0] decoded_input,
    output reg [3:0] select
);
    // Apply tristate buffering based on enable signal using if-else structure
    always @(*) begin
        if (enable) begin
            select = decoded_input;
        end else begin
            select = 4'bzzzz;
        end
    end
endmodule

// Wallace Tree Multiplier for 4-bit operands
module wallace_multiplier(
    input [3:0] a,
    input [3:0] b,
    output [7:0] product
);
    // Partial products generation
    wire [15:0] pp; // 16 partial products for 4x4 multiplication
    
    // Generate partial products
    assign pp[0] = a[0] & b[0];
    assign pp[1] = a[1] & b[0];
    assign pp[2] = a[2] & b[0];
    assign pp[3] = a[3] & b[0];
    assign pp[4] = a[0] & b[1];
    assign pp[5] = a[1] & b[1];
    assign pp[6] = a[2] & b[1];
    assign pp[7] = a[3] & b[1];
    assign pp[8] = a[0] & b[2];
    assign pp[9] = a[1] & b[2];
    assign pp[10] = a[2] & b[2];
    assign pp[11] = a[3] & b[2];
    assign pp[12] = a[0] & b[3];
    assign pp[13] = a[1] & b[3];
    assign pp[14] = a[2] & b[3];
    assign pp[15] = a[3] & b[3];
    
    // Wallace Tree Reduction - Level 1
    wire [5:0] sum1, carry1;
    
    // First column - bit 0
    assign product[0] = pp[0];
    
    // Second column - bit 1
    half_adder ha1(
        .a(pp[1]),
        .b(pp[4]),
        .sum(sum1[0]),
        .cout(carry1[0])
    );
    
    // Third column - bit 2
    full_adder fa1(
        .a(pp[2]),
        .b(pp[5]),
        .cin(pp[8]),
        .sum(sum1[1]),
        .cout(carry1[1])
    );
    
    // Fourth column - bit 3
    full_adder fa2(
        .a(pp[3]),
        .b(pp[6]),
        .cin(pp[9]),
        .sum(sum1[2]),
        .cout(carry1[2])
    );
    
    // Fifth column - bit 4
    full_adder fa3(
        .a(pp[7]),
        .b(pp[10]),
        .cin(pp[13]),
        .sum(sum1[3]),
        .cout(carry1[3])
    );
    
    // Sixth column - bit 5
    full_adder fa4(
        .a(pp[11]),
        .b(pp[14]),
        .cin(1'b0),
        .sum(sum1[4]),
        .cout(carry1[4])
    );
    
    // Seventh column - bit 6
    half_adder ha2(
        .a(pp[15]),
        .b(1'b0),
        .sum(sum1[5]),
        .cout(carry1[5])
    );
    
    // Wallace Tree Reduction - Level 2
    wire [6:0] sum2, carry2;
    
    // First column - bit 1
    assign product[1] = sum1[0];
    
    // Second column - bit 2
    half_adder ha3(
        .a(sum1[1]),
        .b(carry1[0]),
        .sum(sum2[0]),
        .cout(carry2[0])
    );
    
    // Third column - bit 3
    full_adder fa5(
        .a(sum1[2]),
        .b(carry1[1]),
        .cin(pp[12]),
        .sum(sum2[1]),
        .cout(carry2[1])
    );
    
    // Fourth column - bit 4
    full_adder fa6(
        .a(sum1[3]),
        .b(carry1[2]),
        .cin(1'b0),
        .sum(sum2[2]),
        .cout(carry2[2])
    );
    
    // Fifth column - bit 5
    full_adder fa7(
        .a(sum1[4]),
        .b(carry1[3]),
        .cin(1'b0),
        .sum(sum2[3]),
        .cout(carry2[3])
    );
    
    // Sixth column - bit 6
    full_adder fa8(
        .a(sum1[5]),
        .b(carry1[4]),
        .cin(1'b0),
        .sum(sum2[4]),
        .cout(carry2[4])
    );
    
    // Seventh column - bit 7
    half_adder ha4(
        .a(carry1[5]),
        .b(1'b0),
        .sum(sum2[5]),
        .cout(carry2[5])
    );
    
    // Final addition stage with ripple carry adder
    assign product[2] = sum2[0];
    
    wire [4:0] sum_final, carry_final;
    
    // Bit 3
    half_adder ha5(
        .a(sum2[1]),
        .b(carry2[0]),
        .sum(product[3]),
        .cout(carry_final[0])
    );
    
    // Bit 4
    full_adder fa9(
        .a(sum2[2]),
        .b(carry2[1]),
        .cin(carry_final[0]),
        .sum(product[4]),
        .cout(carry_final[1])
    );
    
    // Bit 5
    full_adder fa10(
        .a(sum2[3]),
        .b(carry2[2]),
        .cin(carry_final[1]),
        .sum(product[5]),
        .cout(carry_final[2])
    );
    
    // Bit 6
    full_adder fa11(
        .a(sum2[4]),
        .b(carry2[3]),
        .cin(carry_final[2]),
        .sum(product[6]),
        .cout(carry_final[3])
    );
    
    // Bit 7
    full_adder fa12(
        .a(sum2[5]),
        .b(carry2[4]),
        .cin(carry_final[3]),
        .sum(product[7]),
        .cout()
    );
endmodule

// Half Adder module
module half_adder(
    input a,
    input b,
    output sum,
    output cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule

// Full Adder module
module full_adder(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule