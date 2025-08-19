//SystemVerilog
module AsyncRst_XNOR(
    input rst_n,
    input [3:0] src_a, src_b,
    output reg [3:0] q
);
    wire [7:0] mult_result;
    
    DaddaMultiplier4x4 dadda_mult (
        .a(src_a),
        .b(src_b),
        .p(mult_result)
    );
    
    always @(*) begin
        q = rst_n ? mult_result[3:0] : 4'b0000;
    end
endmodule

module DaddaMultiplier4x4(
    input [3:0] a,
    input [3:0] b,
    output [7:0] p
);
    // Generate partial products
    wire [3:0] pp0, pp1, pp2, pp3;
    
    assign pp0 = b[0] ? a : 4'b0000;
    assign pp1 = b[1] ? a : 4'b0000;
    assign pp2 = b[2] ? a : 4'b0000;
    assign pp3 = b[3] ? a : 4'b0000;
    
    // Dadda reduction stages
    // Stage 1: Generate dots
    wire [15:0] dots;
    
    // Arrange partial products into dots
    assign dots[0] = pp0[0];
    assign dots[1] = pp0[1];
    assign dots[2] = pp0[2];
    assign dots[3] = pp0[3];
    
    assign dots[4] = pp1[0];
    assign dots[5] = pp1[1];
    assign dots[6] = pp1[2];
    assign dots[7] = pp1[3];
    
    assign dots[8] = pp2[0];
    assign dots[9] = pp2[1];
    assign dots[10] = pp2[2];
    assign dots[11] = pp2[3];
    
    assign dots[12] = pp3[0];
    assign dots[13] = pp3[1];
    assign dots[14] = pp3[2];
    assign dots[15] = pp3[3];
    
    // Stage 2: First reduction (4,3,2 counters)
    wire [1:0] s1, s2, s3, s4, s5, s6;
    wire c1, c2, c3, c4, c5, c6;
    
    // Half adders
    assign s1 = dots[4] ^ dots[8];
    assign c1 = dots[4] & dots[8];
    
    assign s2 = dots[5] ^ dots[9];
    assign c2 = dots[5] & dots[9];
    
    // Full adders
    assign s3 = dots[1] ^ dots[5] ^ dots[9];
    assign c3 = (dots[1] & dots[5]) | (dots[5] & dots[9]) | (dots[9] & dots[1]);
    
    assign s4 = dots[2] ^ dots[6] ^ dots[10];
    assign c4 = (dots[2] & dots[6]) | (dots[6] & dots[10]) | (dots[10] & dots[2]);
    
    assign s5 = dots[3] ^ dots[7] ^ dots[11];
    assign c5 = (dots[3] & dots[7]) | (dots[7] & dots[11]) | (dots[11] & dots[3]);
    
    assign s6 = dots[7] ^ dots[11] ^ dots[15];
    assign c6 = (dots[7] & dots[11]) | (dots[11] & dots[15]) | (dots[15] & dots[7]);
    
    // Stage 3: Final addition
    wire [7:0] sum;
    wire [7:0] carry;
    
    // Assign initial values
    assign sum[0] = dots[0];
    assign carry[0] = 1'b0;
    
    assign sum[1] = s1;
    assign carry[1] = c1;
    
    assign sum[2] = s2 ^ dots[12];
    assign carry[2] = s2 & dots[12];
    
    assign sum[3] = s3 ^ dots[13];
    assign carry[3] = s3 & dots[13];
    
    assign sum[4] = s4 ^ dots[14];
    assign carry[4] = s4 & dots[14];
    
    assign sum[5] = s5;
    assign carry[5] = c5;
    
    assign sum[6] = s6;
    assign carry[6] = c6;
    
    assign sum[7] = dots[15];
    assign carry[7] = 1'b0;
    
    // Final addition using carry-skip adder
    CarrySkipAdder #(.WIDTH(8)) final_adder (
        .a(sum),
        .b({carry[6:0], 1'b0}),
        .cin(1'b0),
        .sum(p)
    );
endmodule

module CarrySkipAdder #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum
);
    // Block size for carry-skip logic
    localparam BLOCK_SIZE = 4;
    localparam NUM_BLOCKS = WIDTH / BLOCK_SIZE + (WIDTH % BLOCK_SIZE != 0);
    
    // Internal signals
    wire [WIDTH:0] carry;
    wire [NUM_BLOCKS-1:0] block_propagate;
    
    // Initial carry-in
    assign carry[0] = cin;
    
    // Generate ripple carry adders and skip logic per block
    genvar i, j;
    generate
        for (i = 0; i < NUM_BLOCKS; i = i + 1) begin: blocks
            // Block-level propagate signal
            wire [BLOCK_SIZE-1:0] p;
            wire block_p;
            
            // Calculate propagate signals for each bit in the block
            for (j = 0; j < BLOCK_SIZE; j = j + 1) begin: bits
                if ((i*BLOCK_SIZE + j) < WIDTH) begin
                    // Propagate for each bit position
                    assign p[j] = a[i*BLOCK_SIZE + j] ^ b[i*BLOCK_SIZE + j];
                    
                    // Sum bit
                    assign sum[i*BLOCK_SIZE + j] = p[j] ^ carry[i*BLOCK_SIZE + j];
                    
                    // Carry generation for ripple carry
                    if (j < BLOCK_SIZE-1) begin
                        assign carry[i*BLOCK_SIZE + j + 1] = 
                            (a[i*BLOCK_SIZE + j] & b[i*BLOCK_SIZE + j]) | 
                            (p[j] & carry[i*BLOCK_SIZE + j]);
                    end
                end
            end
            
            // Block propagate signal (AND of all bit propagates)
            if (i == NUM_BLOCKS-1 && WIDTH % BLOCK_SIZE != 0) begin
                // Last block might be partial
                wire [WIDTH % BLOCK_SIZE - 1:0] partial_p;
                for (j = 0; j < WIDTH % BLOCK_SIZE; j = j + 1) begin
                    assign partial_p[j] = p[j];
                end
                assign block_p = &partial_p;
            end else begin
                assign block_p = &p;
            end
            
            // Skip logic for the block
            if (i < NUM_BLOCKS-1) begin
                assign carry[(i+1)*BLOCK_SIZE] = 
                    block_p ? carry[i*BLOCK_SIZE] : 
                    carry[i*BLOCK_SIZE + BLOCK_SIZE-1];
            end
        end
    endgenerate
endmodule