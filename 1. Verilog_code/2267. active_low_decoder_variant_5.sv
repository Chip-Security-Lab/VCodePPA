//SystemVerilog
// Top level module
module active_low_decoder(
    input [2:0] address,
    output [7:0] decode_n,
    // Added ports for multiplier
    input [7:0] a,
    input [7:0] b,
    output [15:0] product
);
    // Internal connections
    wire [7:0] default_value;
    wire [7:0] selected_address;
    
    // Instantiate submodules
    default_generator default_gen_inst (
        .default_value(default_value)
    );
    
    address_decoder addr_dec_inst (
        .address(address),
        .selected_address(selected_address)
    );
    
    output_generator out_gen_inst (
        .default_value(default_value),
        .selected_address(selected_address),
        .decode_n(decode_n)
    );
    
    // Added Wallace tree multiplier
    wallace_tree_multiplier mult_inst (
        .a(a),
        .b(b),
        .product(product)
    );
    
endmodule

// Generate default high values for all outputs
module default_generator(
    output [7:0] default_value
);
    assign default_value = 8'hFF;  // All outputs default to inactive (high)
endmodule

// Decode the input address
module address_decoder(
    input [2:0] address,
    output [7:0] selected_address
);
    // One-hot encoding of the address
    reg [7:0] selected;
    
    always @(*) begin
        selected = 8'h00;
        selected[address] = 1'b1;  // Set the bit corresponding to address
    end
    
    assign selected_address = selected;
endmodule

// Generate the final active-low output
module output_generator(
    input [7:0] default_value,
    input [7:0] selected_address,
    output [7:0] decode_n
);
    // Generate active-low outputs by clearing the bit that matches the address
    assign decode_n = default_value & ~selected_address;
endmodule

// 8-bit Wallace Tree Multiplier implementation
module wallace_tree_multiplier(
    input [7:0] a,
    input [7:0] b,
    output [15:0] product
);
    // Partial products generation
    wire [7:0][7:0] pp;
    
    // Generate partial products
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin: gen_pp_i
            for (j = 0; j < 8; j = j + 1) begin: gen_pp_j
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Wallace tree reduction - Level 1
    wire [14:0] s1_1, c1_1;
    // First group of 3
    full_adder fa1_1_1(.a(pp[0][0]), .b(pp[1][0]), .cin(pp[2][0]), .sum(s1_1[0]), .cout(c1_1[0]));
    full_adder fa1_1_2(.a(pp[0][1]), .b(pp[1][1]), .cin(pp[2][1]), .sum(s1_1[1]), .cout(c1_1[1]));
    full_adder fa1_1_3(.a(pp[0][2]), .b(pp[1][2]), .cin(pp[2][2]), .sum(s1_1[2]), .cout(c1_1[2]));
    full_adder fa1_1_4(.a(pp[0][3]), .b(pp[1][3]), .cin(pp[2][3]), .sum(s1_1[3]), .cout(c1_1[3]));
    full_adder fa1_1_5(.a(pp[0][4]), .b(pp[1][4]), .cin(pp[2][4]), .sum(s1_1[4]), .cout(c1_1[4]));
    full_adder fa1_1_6(.a(pp[0][5]), .b(pp[1][5]), .cin(pp[2][5]), .sum(s1_1[5]), .cout(c1_1[5]));
    full_adder fa1_1_7(.a(pp[0][6]), .b(pp[1][6]), .cin(pp[2][6]), .sum(s1_1[6]), .cout(c1_1[6]));
    full_adder fa1_1_8(.a(pp[0][7]), .b(pp[1][7]), .cin(pp[2][7]), .sum(s1_1[7]), .cout(c1_1[7]));
    
    // Second group of 3
    full_adder fa1_2_1(.a(pp[3][0]), .b(pp[4][0]), .cin(pp[5][0]), .sum(s1_1[8]), .cout(c1_1[8]));
    full_adder fa1_2_2(.a(pp[3][1]), .b(pp[4][1]), .cin(pp[5][1]), .sum(s1_1[9]), .cout(c1_1[9]));
    full_adder fa1_2_3(.a(pp[3][2]), .b(pp[4][2]), .cin(pp[5][2]), .sum(s1_1[10]), .cout(c1_1[10]));
    full_adder fa1_2_4(.a(pp[3][3]), .b(pp[4][3]), .cin(pp[5][3]), .sum(s1_1[11]), .cout(c1_1[11]));
    full_adder fa1_2_5(.a(pp[3][4]), .b(pp[4][4]), .cin(pp[5][4]), .sum(s1_1[12]), .cout(c1_1[12]));
    full_adder fa1_2_6(.a(pp[3][5]), .b(pp[4][5]), .cin(pp[5][5]), .sum(s1_1[13]), .cout(c1_1[13]));
    full_adder fa1_2_7(.a(pp[3][6]), .b(pp[4][6]), .cin(pp[5][6]), .sum(s1_1[14]), .cout(c1_1[14]));
    
    // Wallace tree reduction - Level 2
    wire [13:0] s2_1, c2_1;
    
    // First group of 3
    full_adder fa2_1_1(.a(s1_1[0]), .b(s1_1[8]), .cin(pp[6][0]), .sum(s2_1[0]), .cout(c2_1[0]));
    full_adder fa2_1_2(.a(s1_1[1]), .b(s1_1[9]), .cin(pp[6][1]), .sum(s2_1[1]), .cout(c2_1[1]));
    full_adder fa2_1_3(.a(s1_1[2]), .b(s1_1[10]), .cin(pp[6][2]), .sum(s2_1[2]), .cout(c2_1[2]));
    full_adder fa2_1_4(.a(s1_1[3]), .b(s1_1[11]), .cin(pp[6][3]), .sum(s2_1[3]), .cout(c2_1[3]));
    full_adder fa2_1_5(.a(s1_1[4]), .b(s1_1[12]), .cin(pp[6][4]), .sum(s2_1[4]), .cout(c2_1[4]));
    full_adder fa2_1_6(.a(s1_1[5]), .b(s1_1[13]), .cin(pp[6][5]), .sum(s2_1[5]), .cout(c2_1[5]));
    full_adder fa2_1_7(.a(s1_1[6]), .b(s1_1[14]), .cin(pp[6][6]), .sum(s2_1[6]), .cout(c2_1[6]));
    full_adder fa2_1_8(.a(s1_1[7]), .b(pp[3][7]), .cin(pp[6][7]), .sum(s2_1[7]), .cout(c2_1[7]));
    
    // Process carries
    full_adder fa2_2_1(.a(c1_1[0]), .b(c1_1[8]), .cin(pp[7][0]), .sum(s2_1[8]), .cout(c2_1[8]));
    full_adder fa2_2_2(.a(c1_1[1]), .b(c1_1[9]), .cin(pp[7][1]), .sum(s2_1[9]), .cout(c2_1[9]));
    full_adder fa2_2_3(.a(c1_1[2]), .b(c1_1[10]), .cin(pp[7][2]), .sum(s2_1[10]), .cout(c2_1[10]));
    full_adder fa2_2_4(.a(c1_1[3]), .b(c1_1[11]), .cin(pp[7][3]), .sum(s2_1[11]), .cout(c2_1[11]));
    full_adder fa2_2_5(.a(c1_1[4]), .b(c1_1[12]), .cin(pp[7][4]), .sum(s2_1[12]), .cout(c2_1[12]));
    full_adder fa2_2_6(.a(c1_1[5]), .b(c1_1[13]), .cin(pp[7][5]), .sum(s2_1[13]), .cout(c2_1[13]));
    
    // Final stage - Carry-propagate adder
    wire [15:0] sum, carry;
    
    // First bit is direct
    assign sum[0] = s2_1[0];
    
    // Remaining bits through half/full adders
    half_adder ha_final_1(.a(s2_1[1]), .b(c2_1[0]), .sum(sum[1]), .cout(carry[1]));
    full_adder fa_final_2(.a(s2_1[2]), .b(c2_1[1]), .cin(carry[1]), .sum(sum[2]), .cout(carry[2]));
    full_adder fa_final_3(.a(s2_1[3]), .b(c2_1[2]), .cin(carry[2]), .sum(sum[3]), .cout(carry[3]));
    full_adder fa_final_4(.a(s2_1[4]), .b(c2_1[3]), .cin(carry[3]), .sum(sum[4]), .cout(carry[4]));
    full_adder fa_final_5(.a(s2_1[5]), .b(c2_1[4]), .cin(carry[4]), .sum(sum[5]), .cout(carry[5]));
    full_adder fa_final_6(.a(s2_1[6]), .b(c2_1[5]), .cin(carry[5]), .sum(sum[6]), .cout(carry[6]));
    full_adder fa_final_7(.a(s2_1[7]), .b(c2_1[6]), .cin(carry[6]), .sum(sum[7]), .cout(carry[7]));
    full_adder fa_final_8(.a(s2_1[8]), .b(c2_1[7]), .cin(carry[7]), .sum(sum[8]), .cout(carry[8]));
    full_adder fa_final_9(.a(s2_1[9]), .b(c2_1[8]), .cin(carry[8]), .sum(sum[9]), .cout(carry[9]));
    full_adder fa_final_10(.a(s2_1[10]), .b(c2_1[9]), .cin(carry[9]), .sum(sum[10]), .cout(carry[10]));
    full_adder fa_final_11(.a(s2_1[11]), .b(c2_1[10]), .cin(carry[10]), .sum(sum[11]), .cout(carry[11]));
    full_adder fa_final_12(.a(s2_1[12]), .b(c2_1[11]), .cin(carry[11]), .sum(sum[12]), .cout(carry[12]));
    full_adder fa_final_13(.a(s2_1[13]), .b(c2_1[12]), .cin(carry[12]), .sum(sum[13]), .cout(carry[13]));
    full_adder fa_final_14(.a(pp[4][7]), .b(c2_1[13]), .cin(carry[13]), .sum(sum[14]), .cout(carry[14]));
    full_adder fa_final_15(.a(pp[5][7]), .b(pp[7][7]), .cin(carry[14]), .sum(sum[15]), .cout());
    
    // Assign output
    assign product = sum;
endmodule

// Full adder module
module full_adder(
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

// Half adder module
module half_adder(
    input a, b,
    output sum, cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule