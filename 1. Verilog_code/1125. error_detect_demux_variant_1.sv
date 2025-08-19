//SystemVerilog
module error_detect_demux (
    input wire data,                     // Input data
    input wire [2:0] address,            // Address selection
    output reg [4:0] outputs,            // Output lines
    output reg error_flag                // Error indication
);
    // One-hot encoding for better PPA characteristics
    reg [4:0] address_decoded;
    
    // 5-bit multiplier inputs (derived from address and data)
    wire [4:0] mult_a, mult_b;
    wire [9:0] mult_result;
    
    // Connect multiplier inputs based on address and data
    assign mult_a = {2'b0, address};
    assign mult_b = {4'b0, data};
    
    // Instantiate Wallace tree multiplier
    wallace_tree_multiplier wallace_mult (
        .a(mult_a),
        .b(mult_b),
        .product(mult_result)
    );
    
    always @(*) begin
        // Initialize outputs
        outputs = 5'b00000;
        error_flag = 1'b0;
        
        // Decode address to one-hot encoding for valid addresses (0-4)
        address_decoded = 5'b00000;
        case(address)
            3'b000: address_decoded = 5'b00001;
            3'b001: address_decoded = 5'b00010;
            3'b010: address_decoded = 5'b00100;
            3'b011: address_decoded = 5'b01000;
            3'b100: address_decoded = 5'b10000;
            default: address_decoded = 5'b00000; // Invalid address
        endcase
        
        // Route data to appropriate output or set error flag
        if (|address_decoded) begin
            // Valid address (0-4)
            outputs = address_decoded & {5{data}};
            
            // Use multiplication result to influence outputs if data is 1
            if (data) begin
                outputs = outputs ^ mult_result[4:0];
            end
        end else begin
            // Invalid address (5-7), set error flag if data is 1
            error_flag = data;
        end
    end
endmodule

// Wallace Tree Multiplier for 5-bit operands
module wallace_tree_multiplier (
    input wire [4:0] a,    // 5-bit multiplicand
    input wire [4:0] b,    // 5-bit multiplier
    output wire [9:0] product // 10-bit product
);
    // Generate partial products
    wire [4:0] pp0, pp1, pp2, pp3, pp4;
    
    assign pp0 = a & {5{b[0]}};
    assign pp1 = a & {5{b[1]}};
    assign pp2 = a & {5{b[2]}};
    assign pp3 = a & {5{b[3]}};
    assign pp4 = a & {5{b[4]}};
    
    // Level 1: First stage of Wallace reduction
    wire [5:0] s1_1, c1_1; // Sum and carry from first group
    wire [4:0] s1_2, c1_2; // Sum and carry from second group
    
    // First group: Add pp0, pp1, pp2
    full_adder fa1_0 (.a(pp0[0]), .b(pp1[0]), .cin(pp2[0]), .sum(s1_1[0]), .cout(c1_1[0]));
    full_adder fa1_1 (.a(pp0[1]), .b(pp1[1]), .cin(pp2[1]), .sum(s1_1[1]), .cout(c1_1[1]));
    full_adder fa1_2 (.a(pp0[2]), .b(pp1[2]), .cin(pp2[2]), .sum(s1_1[2]), .cout(c1_1[2]));
    full_adder fa1_3 (.a(pp0[3]), .b(pp1[3]), .cin(pp2[3]), .sum(s1_1[3]), .cout(c1_1[3]));
    full_adder fa1_4 (.a(pp0[4]), .b(pp1[4]), .cin(pp2[4]), .sum(s1_1[4]), .cout(c1_1[4]));
    assign s1_1[5] = 1'b0;
    assign c1_1[5] = 1'b0;
    
    // Second group: Add pp3, pp4
    half_adder ha1_0 (.a(pp3[0]), .b(pp4[0]), .sum(s1_2[0]), .cout(c1_2[0]));
    half_adder ha1_1 (.a(pp3[1]), .b(pp4[1]), .sum(s1_2[1]), .cout(c1_2[1]));
    half_adder ha1_2 (.a(pp3[2]), .b(pp4[2]), .sum(s1_2[2]), .cout(c1_2[2]));
    half_adder ha1_3 (.a(pp3[3]), .b(pp4[3]), .sum(s1_2[3]), .cout(c1_2[3]));
    half_adder ha1_4 (.a(pp3[4]), .b(pp4[4]), .sum(s1_2[4]), .cout(c1_2[4]));
    
    // Level 2: Second stage of Wallace reduction
    wire [6:0] s2, c2;
    
    // Add s1_1, c1_1 (shifted), s1_2
    assign s2[0] = s1_1[0];
    half_adder ha2_0 (.a(s1_1[1]), .b(c1_1[0]), .sum(s2[1]), .cout(c2[0]));
    full_adder fa2_0 (.a(s1_1[2]), .b(c1_1[1]), .cin(s1_2[0]), .sum(s2[2]), .cout(c2[1]));
    full_adder fa2_1 (.a(s1_1[3]), .b(c1_1[2]), .cin(s1_2[1]), .sum(s2[3]), .cout(c2[2]));
    full_adder fa2_2 (.a(s1_1[4]), .b(c1_1[3]), .cin(s1_2[2]), .sum(s2[4]), .cout(c2[3]));
    full_adder fa2_3 (.a(s1_1[5]), .b(c1_1[4]), .cin(s1_2[3]), .sum(s2[5]), .cout(c2[4]));
    half_adder ha2_1 (.a(c1_1[5]), .b(s1_2[4]), .sum(s2[6]), .cout(c2[5]));
    assign c2[6] = c1_2[4];
    
    // Level 3: Add c1_2 (shifted) to remaining sums and carries
    wire [8:0] s3, c3;
    
    assign s3[0] = s2[0];
    assign s3[1] = s2[1];
    
    half_adder ha3_0 (.a(s2[2]), .b(c1_2[0]), .sum(s3[2]), .cout(c3[0]));
    full_adder fa3_0 (.a(s2[3]), .b(c2[1]), .cin(c1_2[1]), .sum(s3[3]), .cout(c3[1]));
    full_adder fa3_1 (.a(s2[4]), .b(c2[2]), .cin(c1_2[2]), .sum(s3[4]), .cout(c3[2]));
    full_adder fa3_2 (.a(s2[5]), .b(c2[3]), .cin(c1_2[3]), .sum(s3[5]), .cout(c3[3]));
    full_adder fa3_3 (.a(s2[6]), .b(c2[4]), .cin(c2[0]), .sum(s3[6]), .cout(c3[4]));
    half_adder ha3_1 (.a(c2[5]), .b(c2[6]), .sum(s3[7]), .cout(c3[5]));
    assign s3[8] = 1'b0;
    assign c3[6] = 1'b0;
    assign c3[7] = 1'b0;
    assign c3[8] = 1'b0;
    
    // Final addition using ripple carry adder
    wire [9:0] s_final, c_final;
    
    assign s_final[0] = s3[0];
    half_adder ha_f0 (.a(s3[1]), .b(c3[0]), .sum(s_final[1]), .cout(c_final[0]));
    half_adder ha_f1 (.a(s3[2]), .b(c3[1]), .sum(s_final[2]), .cout(c_final[1]));
    full_adder fa_f0 (.a(s3[3]), .b(c3[2]), .cin(c_final[0]), .sum(s_final[3]), .cout(c_final[2]));
    full_adder fa_f1 (.a(s3[4]), .b(c3[3]), .cin(c_final[1]), .sum(s_final[4]), .cout(c_final[3]));
    full_adder fa_f2 (.a(s3[5]), .b(c3[4]), .cin(c_final[2]), .sum(s_final[5]), .cout(c_final[4]));
    full_adder fa_f3 (.a(s3[6]), .b(c3[5]), .cin(c_final[3]), .sum(s_final[6]), .cout(c_final[5]));
    full_adder fa_f4 (.a(s3[7]), .b(c3[6]), .cin(c_final[4]), .sum(s_final[7]), .cout(c_final[6]));
    full_adder fa_f5 (.a(s3[8]), .b(c3[7]), .cin(c_final[5]), .sum(s_final[8]), .cout(c_final[7]));
    half_adder ha_f2 (.a(c3[8]), .b(c_final[6]), .sum(s_final[9]), .cout(c_final[8]));
    
    // Final product
    assign product = s_final;
endmodule

// Full Adder module
module full_adder (
    input wire a, b, cin,
    output wire sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

// Half Adder module
module half_adder (
    input wire a, b,
    output wire sum, cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule