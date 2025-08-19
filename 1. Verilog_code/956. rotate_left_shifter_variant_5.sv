//SystemVerilog
module rotate_left_shifter (
    input clk, rst, enable,
    input [7:0] multiplicand, multiplier,
    input mult_enable,
    output reg [7:0] data_out
);
    // Pre-load with pattern
    initial data_out = 8'b10101010;
    
    // Control signal combination for case statement
    reg [2:0] ctrl;
    wire [7:0] mult_result;
    
    // Instantiate the Dadda multiplier
    dadda_multiplier u_dadda_multiplier(
        .a(multiplicand),
        .b(multiplier),
        .product(mult_result)
    );
    
    always @(*) begin
        ctrl = {rst, enable, mult_enable};
    end
    
    always @(posedge clk) begin
        case (ctrl)
            3'b100, 3'b101, 3'b110, 3'b111: data_out <= 8'b10101010;    // Reset has priority
            3'b001:        data_out <= {data_out[6:0], data_out[7]};     // Enable active, no reset, no mult
            3'b011:        data_out <= mult_result;                      // Mult operation, no reset
            3'b000:        data_out <= data_out;                         // Hold value
            default:       data_out <= 8'b10101010;                      // Default case for safety
        endcase
    end
endmodule

// Dadda Multiplier 8-bit implementation
module dadda_multiplier (
    input [7:0] a,
    input [7:0] b,
    output [7:0] product
);
    // Partial products generation
    wire [7:0] pp[7:0];
    
    // Generate partial products
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin: pp_gen_i
            for (j = 0; j < 8; j = j + 1) begin: pp_gen_j
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Dadda tree reduction - Layer 1 (height 6)
    wire [14:0] s1, c1;
    
    // Compression stage 1 - using half and full adders
    half_adder ha1_1(.a(pp[6][0]), .b(pp[5][1]), .sum(s1[0]), .cout(c1[0]));
    full_adder fa1_1(.a(pp[4][2]), .b(pp[3][3]), .cin(pp[2][4]), .sum(s1[1]), .cout(c1[1]));
    full_adder fa1_2(.a(pp[7][0]), .b(pp[6][1]), .cin(pp[5][2]), .sum(s1[2]), .cout(c1[2]));
    full_adder fa1_3(.a(pp[4][3]), .b(pp[3][4]), .cin(pp[2][5]), .sum(s1[3]), .cout(c1[3]));
    half_adder ha1_2(.a(pp[1][6]), .b(pp[0][7]), .sum(s1[4]), .cout(c1[4]));
    full_adder fa1_4(.a(pp[7][1]), .b(pp[6][2]), .cin(pp[5][3]), .sum(s1[5]), .cout(c1[5]));
    full_adder fa1_5(.a(pp[4][4]), .b(pp[3][5]), .cin(pp[2][6]), .sum(s1[6]), .cout(c1[6]));
    full_adder fa1_6(.a(pp[7][2]), .b(pp[6][3]), .cin(pp[5][4]), .sum(s1[7]), .cout(c1[7]));
    full_adder fa1_7(.a(pp[4][5]), .b(pp[3][6]), .cin(pp[2][7]), .sum(s1[8]), .cout(c1[8]));
    full_adder fa1_8(.a(pp[7][3]), .b(pp[6][4]), .cin(pp[5][5]), .sum(s1[9]), .cout(c1[9]));
    full_adder fa1_9(.a(pp[7][4]), .b(pp[6][5]), .cin(pp[5][6]), .sum(s1[10]), .cout(c1[10]));
    half_adder ha1_3(.a(pp[4][7]), .b(pp[3][7]), .sum(s1[11]), .cout(c1[11]));
    half_adder ha1_4(.a(pp[7][5]), .b(pp[6][6]), .sum(s1[12]), .cout(c1[12]));
    half_adder ha1_5(.a(pp[7][6]), .b(pp[6][7]), .sum(s1[13]), .cout(c1[13]));
    assign s1[14] = pp[7][7];
    
    // Dadda tree reduction - Layer 2 (height 4)
    wire [14:0] s2, c2;
    
    // Layer 2 reductions
    assign s2[0] = pp[4][0];
    half_adder ha2_1(.a(pp[3][1]), .b(pp[2][2]), .sum(s2[1]), .cout(c2[0]));
    full_adder fa2_1(.a(pp[1][3]), .b(pp[0][4]), .cin(s1[0]), .sum(s2[2]), .cout(c2[1]));
    full_adder fa2_2(.a(pp[1][4]), .b(pp[0][5]), .cin(s1[1]), .sum(s2[3]), .cout(c2[2]));
    full_adder fa2_3(.a(c1[0]), .b(pp[1][5]), .cin(pp[0][6]), .sum(s2[4]), .cout(c2[3]));
    full_adder fa2_4(.a(c1[1]), .b(s1[2]), .cin(c1[2]), .sum(s2[5]), .cout(c2[4]));
    full_adder fa2_5(.a(s1[3]), .b(c1[3]), .cin(s1[4]), .sum(s2[6]), .cout(c2[5]));
    full_adder fa2_6(.a(c1[4]), .b(s1[5]), .cin(c1[5]), .sum(s2[7]), .cout(c2[6]));
    full_adder fa2_7(.a(s1[6]), .b(c1[6]), .cin(s1[7]), .sum(s2[8]), .cout(c2[7]));
    full_adder fa2_8(.a(c1[7]), .b(s1[8]), .cin(c1[8]), .sum(s2[9]), .cout(c2[8]));
    full_adder fa2_9(.a(s1[9]), .b(c1[9]), .cin(s1[10]), .sum(s2[10]), .cout(c2[9]));
    full_adder fa2_10(.a(c1[10]), .b(s1[11]), .cin(c1[11]), .sum(s2[11]), .cout(c2[10]));
    full_adder fa2_11(.a(s1[12]), .b(c1[12]), .cin(s1[13]), .sum(s2[12]), .cout(c2[11]));
    half_adder ha2_2(.a(c1[13]), .b(s1[14]), .sum(s2[13]), .cout(c2[12]));
    assign s2[14] = 1'b0;
    
    // Dadda tree reduction - Layer 3 (height 2)
    wire [14:0] s3, c3;
    
    // Layer 3 reductions
    assign s3[0] = pp[2][0];
    half_adder ha3_1(.a(pp[1][1]), .b(pp[0][2]), .sum(s3[1]), .cout(c3[0]));
    full_adder fa3_1(.a(pp[3][0]), .b(pp[2][1]), .cin(pp[1][2]), .sum(s3[2]), .cout(c3[1]));
    full_adder fa3_2(.a(pp[0][3]), .b(s2[0]), .cin(s2[1]), .sum(s3[3]), .cout(c3[2]));
    full_adder fa3_3(.a(c2[0]), .b(s2[2]), .cin(c2[1]), .sum(s3[4]), .cout(c3[3]));
    full_adder fa3_4(.a(s2[3]), .b(c2[2]), .cin(s2[4]), .sum(s3[5]), .cout(c3[4]));
    full_adder fa3_5(.a(c2[3]), .b(s2[5]), .cin(c2[4]), .sum(s3[6]), .cout(c3[5]));
    full_adder fa3_6(.a(s2[6]), .b(c2[5]), .cin(s2[7]), .sum(s3[7]), .cout(c3[6]));
    full_adder fa3_7(.a(c2[6]), .b(s2[8]), .cin(c2[7]), .sum(s3[8]), .cout(c3[7]));
    full_adder fa3_8(.a(s2[9]), .b(c2[8]), .cin(s2[10]), .sum(s3[9]), .cout(c3[8]));
    full_adder fa3_9(.a(c2[9]), .b(s2[11]), .cin(c2[10]), .sum(s3[10]), .cout(c3[9]));
    full_adder fa3_10(.a(s2[12]), .b(c2[11]), .cin(s2[13]), .sum(s3[11]), .cout(c3[10]));
    half_adder ha3_2(.a(c2[12]), .b(s2[14]), .sum(s3[12]), .cout(c3[11]));
    assign s3[13] = 1'b0;
    assign s3[14] = 1'b0;
    
    // Final addition stage
    wire [15:0] sum;
    wire [15:0] carry;
    
    // First bit is just pp[0][0]
    assign sum[0] = pp[0][0];
    assign carry[0] = 1'b0;
    
    // Second bit
    half_adder ha_f0(.a(pp[1][0]), .b(pp[0][1]), .sum(sum[1]), .cout(carry[1]));
    
    // Remaining bits
    genvar k;
    generate
        for (k = 2; k < 15; k = k + 1) begin: final_adder
            full_adder fa_f(.a(s3[k-2]), .b(c3[k-3]), .cin(carry[k-1]), .sum(sum[k]), .cout(carry[k]));
        end
    endgenerate
    
    // MSB carry
    assign sum[15] = carry[14];
    
    // Take only lower 8 bits for output
    assign product = sum[7:0];
endmodule

// Half Adder
module half_adder (
    input a, b,
    output sum, cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule

// Full Adder
module full_adder (
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule