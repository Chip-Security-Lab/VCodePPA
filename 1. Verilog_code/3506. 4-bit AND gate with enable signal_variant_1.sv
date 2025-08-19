//SystemVerilog
// Top module: 4-bit multiplier using Dadda algorithm with enable signal
module and_gate_4_enable (
    input wire [3:0] a,      // 4-bit input A
    input wire [3:0] b,      // 4-bit input B
    input wire enable,       // Enable signal
    output wire [7:0] y      // 8-bit output Y (result of multiplication)
);
    wire [7:0] mult_result;
    
    // Instantiate the Dadda multiplier
    dadda_multiplier_4bit dadda_mult (
        .a(a),
        .b(b),
        .p(mult_result)
    );
    
    // Control output with enable signal - optimized using bit-wise AND
    assign y = {8{enable}} & mult_result;
endmodule

// Dadda multiplier 4-bit implementation
module dadda_multiplier_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [7:0] p
);
    // Partial products generation - optimized array format
    wire [3:0][3:0] pp; // Reorganized as 2D array for clarity
    
    // Generate partial products with optimized indexing
    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_pp_i
            for (j = 0; j < 4; j = j + 1) begin : gen_pp_j
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Dadda reduction layers
    // Wires for the first reduction layer
    wire [5:0] s1, c1;
    
    // First reduction layer (from height 4 to 3)
    half_adder ha1(.a(pp[1][2]), .b(pp[2][0]), .sum(s1[0]), .cout(c1[0]));
    full_adder fa1(.a(pp[1][3]), .b(pp[2][1]), .cin(pp[2][3]), .sum(s1[1]), .cout(c1[1]));
    half_adder ha2(.a(pp[2][2]), .b(pp[3][0]), .sum(s1[2]), .cout(c1[2]));
    full_adder fa2(.a(pp[2][3]), .b(pp[3][1]), .cin(pp[3][3]), .sum(s1[3]), .cout(c1[3]));
    half_adder ha3(.a(pp[3][2]), .b(c1[2]), .sum(s1[4]), .cout(c1[4]));
    half_adder ha4(.a(c1[1]), .b(c1[3]), .sum(s1[5]), .cout(c1[5]));
    
    // Wires for the second reduction layer
    wire [6:0] s2, c2;
    
    // Second reduction layer (from height 3 to 2)
    half_adder ha5(.a(pp[1][0]), .b(pp[0][1]), .sum(s2[0]), .cout(c2[0]));
    full_adder fa3(.a(pp[1][1]), .b(pp[0][2]), .cin(pp[0][0]), .sum(s2[1]), .cout(c2[1]));
    full_adder fa4(.a(s1[0]), .b(pp[0][3]), .cin(c2[0]), .sum(s2[2]), .cout(c2[2]));
    full_adder fa5(.a(s1[1]), .b(s1[2]), .cin(c2[1]), .sum(s2[3]), .cout(c2[3]));
    full_adder fa6(.a(s1[3]), .b(s1[4]), .cin(c2[2]), .sum(s2[4]), .cout(c2[4]));
    full_adder fa7(.a(s1[5]), .b(c1[4]), .cin(c2[3]), .sum(s2[5]), .cout(c2[5]));
    half_adder ha6(.a(c1[5]), .b(c2[4]), .sum(s2[6]), .cout(c2[6]));
    
    // Final addition using carry propagate adder - direct assignment
    wire [7:0] cpa_a, cpa_b;
    
    // Prepare inputs for the final CPA with simplified bit assignments
    assign cpa_a = {1'b0, c2[6], s2[6], s2[5], s2[4], s2[3], s2[2], s2[1]};
    assign cpa_b = {2'b0, c2[5], c2[4], c2[3], c2[2], c2[1], s2[0]};
    
    // Final addition - direct output assignment
    assign p = cpa_a + cpa_b; // Use built-in operator for better synthesis
endmodule

// Half Adder module - optimized
module half_adder (
    input wire a,
    input wire b,
    output wire sum,
    output wire cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule

// Full Adder module - optimized using Boolean simplification
module full_adder (
    input wire a,
    input wire b,
    input wire cin,
    output wire sum,
    output wire cout
);
    wire ab_xor;
    assign ab_xor = a ^ b;
    assign sum = ab_xor ^ cin;
    assign cout = (ab_xor & cin) | (a & b);
endmodule