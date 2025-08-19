//SystemVerilog
module hamming_dec_direct(
    input [6:0] code_in,
    output [3:0] data_out,
    output error
);

    wire [2:0] syndrome;
    reg [6:0] corrected;
    
    // Calculate syndrome using Dadda multiplier structure
    wire [6:0] p0, p1, p2;
    wire [6:0] s0, s1, s2;
    
    // Generate partial products
    assign p0 = code_in & {7{code_in[0]}};
    assign p1 = code_in & {7{code_in[2]}};
    assign p2 = code_in & {7{code_in[4]}};
    
    // Dadda tree reduction
    wire [6:0] c1, c2;
    wire [6:0] sum1, sum2;
    
    // First stage
    assign s0 = p0 ^ p1;
    assign c1 = p0 & p1;
    
    // Second stage
    assign s1 = s0 ^ p2;
    assign c2 = s0 & p2;
    
    // Final stage
    assign s2 = s1 ^ c1;
    assign syndrome[0] = s2[0] ^ code_in[6];
    
    // Similar structure for syndrome[1] and syndrome[2]
    wire [6:0] p3, p4, p5;
    wire [6:0] s3, s4, s5;
    
    assign p3 = code_in & {7{code_in[1]}};
    assign p4 = code_in & {7{code_in[2]}};
    assign p5 = code_in & {7{code_in[5]}};
    
    wire [6:0] c3, c4;
    wire [6:0] sum3, sum4;
    
    assign s3 = p3 ^ p4;
    assign c3 = p3 & p4;
    
    assign s4 = s3 ^ p5;
    assign c4 = s3 & p5;
    
    assign s5 = s4 ^ c3;
    assign syndrome[1] = s5[0] ^ code_in[6];
    
    wire [6:0] p6, p7, p8;
    wire [6:0] s6, s7, s8;
    
    assign p6 = code_in & {7{code_in[3]}};
    assign p7 = code_in & {7{code_in[4]}};
    assign p8 = code_in & {7{code_in[5]}};
    
    wire [6:0] c5, c6;
    wire [6:0] sum5, sum6;
    
    assign s6 = p6 ^ p7;
    assign c5 = p6 & p7;
    
    assign s7 = s6 ^ p8;
    assign c6 = s6 & p8;
    
    assign s8 = s7 ^ c5;
    assign syndrome[2] = s8[0] ^ code_in[6];
    
    // Apply correction using if-else structure
    always @(*) begin
        if (syndrome == 3'b000)
            corrected = code_in;
        else if (syndrome == 3'b001)
            corrected = code_in ^ 7'b0000001;
        else if (syndrome == 3'b010)
            corrected = code_in ^ 7'b0000010;
        else if (syndrome == 3'b011)
            corrected = code_in ^ 7'b0000100;
        else if (syndrome == 3'b100)
            corrected = code_in ^ 7'b0001000;
        else if (syndrome == 3'b101)
            corrected = code_in ^ 7'b0010000;
        else if (syndrome == 3'b110)
            corrected = code_in ^ 7'b0100000;
        else
            corrected = code_in ^ 7'b1000000;
    end
    
    // Extract data bits
    assign data_out = {corrected[6], corrected[5], corrected[4], corrected[2]};
    assign error = |syndrome;

endmodule