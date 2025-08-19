module BasicIVMU (
    input wire clk, rst_n,
    input wire [7:0] int_req,
    output reg [31:0] vector_addr,
    output reg int_valid
);

    localparam BASE_ADDR = 32'h1000_0000;

    // Combinational logic to determine interrupt status and vector address
    wire [2:0] highest_priority_idx;
    wire interrupt_pending;
    wire [31:0] next_vector_addr; // Output of the CLA adder

    // Determine if any interrupt is pending
    assign interrupt_pending = |int_req;

    // Priority encoder: Find the index of the highest set bit (priority 7 down to 0)
    assign highest_priority_idx =
        int_req[7] ? 3'd7 :
        int_req[6] ? 3'd6 :
        int_req[5] ? 3'd5 :
        int_req[4] ? 3'd4 :
        int_req[3] ? 3'd3 :
        int_req[2] ? 3'd2 :
        int_req[1] ? 3'd1 :
        3'd0; // If interrupt_pending is true, but none above, it must be bit 0

    // Calculate the offset: index * 4 (left shift by 2)
    wire [31:0] index_offset = { {29{1'b0}}, highest_priority_idx } << 2;

    // Instantiate the 32-bit CLA adder
    // Inputs are BASE_ADDR and index_offset
    wire cla_cout; // Carry out - not used in this context as we don't expect overflow

    cla_adder_32bit vector_addr_adder (
        .a(BASE_ADDR),
        .b(index_offset),
        .cin(1'b0), // No carry-in for simple addition
        .sum(next_vector_addr),
        .cout(cla_cout)
    );

    // Synchronous logic to register the results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vector_addr <= 32'h0;
            int_valid <= 1'b0;
        end else begin
            if (interrupt_pending) begin
                vector_addr <= next_vector_addr;
                int_valid <= 1'b1;
            end else begin
                vector_addr <= 32'h0; // Default value when no interrupt is pending
                int_valid <= 1'b0;   // Default value when no interrupt is pending
            end
        end
    end

endmodule

// 32-bit Carry-Lookahead Adder Module
module cla_adder_32bit (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire cin,
    output wire [31:0] sum,
    output wire cout
);

    // Bit-level propagate and generate
    wire [31:0] p = a ^ b;
    wire [31:0] g = a & b;

    // Block-level propagate and generate (8 blocks of 4 bits)
    wire [7:0] P_block; // P_block[i] is propagate for block i (bits 4i to 4i+3)
    wire [7:0] G_block; // G_block[i] is generate for block i (bits 4i to 4i+3)

    // Carries into each block (C_in_block[i] is carry into bit 4*i)
    wire [8:0] C_in_block;
    assign C_in_block[0] = cin; // Overall carry-in

    // Carries into each bit position (c_in_bit[i] is carry into bit i)
    wire [32:0] c_in_bit; // c_in_bit[32] is the overall carry out

    // Calculate block P and G, and internal carries within blocks
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : block_gen
            localparam start_bit = i * 4;
            localparam end_bit = start_bit + 3;

            // Block P and G
            assign P_block[i] = p[end_bit] & p[end_bit-1] & p[end_bit-2] & p[start_bit];
            assign G_block[i] = g[end_bit] | (p[end_bit] & g[end_bit-1]) | (p[end_bit] & p[end_bit-1] & g[end_bit-2]) | (p[end_bit] & p[end_bit-1] & p[end_bit-2] & g[start_bit]);

            // Carry into the first bit of block i is the block carry-in
            assign c_in_bit[start_bit] = C_in_block[i];

            // Carries within block i based on block carry-in
            if (start_bit + 1 < 32) assign c_in_bit[start_bit+1] = g[start_bit] | (p[start_bit] & c_in_bit[start_bit]);
            if (start_bit + 2 < 32) assign c_in_bit[start_bit+2] = g[start_bit+1] | (p[start_bit+1] & c_in_bit[start_bit+1]);
            if (start_bit + 3 < 32) assign c_in_bit[start_bit+3] = g[start_bit+2] | (p[start_bit+2] & c_in_bit[start_bit+2]);

            // The carry out of block i is c_in_bit[start_bit+4]
            // This is calculated by the block-level carry lookahead logic below
            // which defines C_in_block[i+1].
        end
    endgenerate

    // Block-level carry lookahead
    // C_in_block[i+1] = G_block[i] | (P_block[i] & C_in_block[i])
    assign C_in_block[1] = G_block[0] | (P_block[0] & C_in_block[0]);
    assign C_in_block[2] = G_block[1] | (P_block[1] & C_in_block[1]);
    assign C_in_block[3] = G_block[2] | (P_block[2] & C_in_block[2]);
    assign C_in_block[4] = G_block[3] | (P_block[3] & C_in_block[3]);
    assign C_in_block[5] = G_block[4] | (P_block[4] & C_in_block[4]);
    assign C_in_block[6] = G_block[5] | (P_block[5] & C_in_block[5]);
    assign C_in_block[7] = G_block[6] | (P_block[6] & C_in_block[6]);
    assign C_in_block[8] = G_block[7] | (P_block[7] & C_in_block[7]); // Overall carry out

    // Sum bits: sum[i] = p[i] ^ c_in_bit[i]
    assign sum = p ^ c_in_bit[31:0];

    // Overall carry out is the carry out of the last block
    assign cout = C_in_block[8];

endmodule