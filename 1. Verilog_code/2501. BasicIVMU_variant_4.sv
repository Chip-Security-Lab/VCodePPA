// 4-bit Carry Lookahead Adder Block
module cla_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    input wire cin,
    output wire [3:0] sum,
    output wire cout,
    output wire pg, // Group Propagate
    output wire gg  // Group Generate
);

    wire [3:0] p; // Propagate signals
    wire [3:0] g; // Generate signals
    wire [4:0] c; // Internal carries (c[0] is cin)

    // Calculate P and G for each bit
    assign p = a ^ b;
    assign g = a & b;

    // Assign carry-in to the first internal carry
    assign c[0] = cin;

    // Calculate internal carries using lookahead logic
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g[3] | (p[3] & c[3]); // This is the group carry-out

    // Calculate sum bits
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];

    // Assign outputs
    assign cout = c[4];
    assign pg = p[0] & p[1] & p[2] & p[3];
    assign gg = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);

endmodule

// Top-level Carry Lookahead Unit for 8 groups (32 bits)
module cla_top_8group (
    input wire [7:0] pg_in, // Group Propagate inputs
    input wire [7:0] gg_in, // Group Generate inputs
    input wire cin,         // System Carry-in
    output wire [7:0] c_out_group // Carry-in for each group (C0, C4, ..., C28)
);

    // c_out_group[k] is the carry-in to group k
    assign c_out_group[0] = cin;
    assign c_out_group[1] = gg_in[0] | (pg_in[0] & c_out_group[0]);
    assign c_out_group[2] = gg_in[1] | (pg_in[1] & c_out_group[1]);
    assign c_out_group[3] = gg_in[2] | (pg_in[2] & c_out_group[2]);
    assign c_out_group[4] = gg_in[3] | (pg_in[3] & c_out_group[3]);
    assign c_out_group[5] = gg_in[4] | (pg_in[4] & c_out_group[4]);
    assign c_out_group[6] = gg_in[5] | (pg_in[5] & c_out_group[5]);
    assign c_out_group[7] = gg_in[6] | (pg_in[6] & c_out_group[6]);

endmodule

// 32-bit Carry Lookahead Adder
module cla_32bit (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire cin,
    output wire [31:0] sum,
    output wire cout
);

    wire [7:0] pg_groups; // Group Propagate signals
    wire [7:0] gg_groups; // Group Generate signals
    wire [7:0] group_carries_in; // Carry-in for each 4-bit group (C0, C4, ..., C28)
    wire [7:0] group_carries_out; // Carry-out from each 4-bit group (C4, C8, ..., C32)

    // Instantiate the top-level carry lookahead unit
    cla_top_8group u_cla_top (
        .pg_in(pg_groups),
        .gg_in(gg_groups),
        .cin(cin),
        .c_out_group(group_carries_in)
    );

    // Instantiate eight 4-bit CLA blocks
    cla_4bit u_cla_group0 (
        .a(a[3:0]), .b(b[3:0]), .cin(group_carries_in[0]),
        .sum(sum[3:0]), .cout(group_carries_out[0]),
        .pg(pg_groups[0]), .gg(gg_groups[0])
    );

    cla_4bit u_cla_group1 (
        .a(a[7:4]), .b(b[7:4]), .cin(group_carries_in[1]),
        .sum(sum[7:4]), .cout(group_carries_out[1]),
        .pg(pg_groups[1]), .gg(gg_groups[1])
    );

    cla_4bit u_cla_group2 (
        .a(a[11:8]), .b(b[11:8]), .cin(group_carries_in[2]),
        .sum(sum[11:8]), .cout(group_carries_out[2]),
        .pg(pg_groups[2]), .gg(gg_groups[2])
    );

    cla_4bit u_cla_group3 (
        .a(a[15:12]), .b(b[15:12]), .cin(group_carries_in[3]),
        .sum(sum[15:12]), .cout(group_carries_out[3]),
        .pg(pg_groups[3]), .gg(gg_groups[3])
    );

    cla_4bit u_cla_group4 (
        .a(a[19:16]), .b(b[19:16]), .cin(group_carries_in[4]),
        .sum(sum[19:16]), .cout(group_carries_out[4]),
        .pg(pg_groups[4]), .gg(gg_groups[4])
    );

    cla_4bit u_cla_group5 (
        .a(a[23:20]), .b(b[23:20]), .cin(group_carries_in[5]),
        .sum(sum[23:20]), .cout(group_carries_out[5]),
        .pg(pg_groups[5]), .gg(gg_groups[5])
    );

    cla_4bit u_cla_group6 (
        .a(a[27:24]), .b(b[27:24]), .cin(group_carries_in[6]),
        .sum(sum[27:24]), .cout(group_carries_out[6]),
        .pg(pg_groups[6]), .gg(gg_groups[6])
    );

    cla_4bit u_cla_group7 (
        .a(a[31:28]), .b(b[31:28]), .cin(group_carries_in[7]),
        .sum(sum[31:28]), .cout(group_carries_out[7]),
        .pg(pg_groups[7]), .gg(gg_groups[7])
    );

    // The final carry-out is the carry-out of the last group
    assign cout = group_carries_out[7];

endmodule

module BasicIVMU (
    input wire clk,
    input wire rst_n,
    input wire [7:0] int_req,
    output reg [31:0] vector_addr,
    output reg int_valid
);

    // Keep the initial block and vec_table as in the original code
    // This initializes the memory contents, although the dynamic logic
    // now calculates the address directly using the CLA adder.
    // This maintains the original structure and initial state.
    reg [31:0] vec_table [0:7];
    integer i;

    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            vec_table[i] = 32'h1000_0000 + (i << 2);
        end
    end

    // Define the base address for dynamic calculation
    localparam [31:0] BASE_VECTOR_ADDR = 32'h1000_0000;

    // Wires for dynamic address calculation using CLA
    wire [2:0] priority_index;
    wire [31:0] offset;
    wire [31:0] calculated_addr;
    wire carry_out; // Unused carry out from CLA

    // Combinational logic to determine priority index and offset
    // This replaces the if-else if structure for address selection from vec_table
    assign priority_index =
        int_req[7] ? 3'd7 :
        int_req[6] ? 3'd6 :
        int_req[5] ? 3'd5 :
        int_req[4] ? 3'd4 :
        int_req[3] ? 3'd3 :
        int_req[2] ? 3'd2 :
        int_req[1] ? 3'd1 :
        3'd0; // Default if int_req is not 0 (implies int_req[0] is high)

    // Calculate offset: index * 4 (index << 2)
    assign offset = priority_index << 2;

    // Instantiate the 32-bit CLA adder for dynamic address calculation
    // This adder is part of the combinational logic path feeding the vector_addr register
    cla_32bit u_addr_adder (
        .a(BASE_VECTOR_ADDR),
        .b(offset),
        .cin(1'b0), // Standard addition has carry-in 0
        .sum(calculated_addr),
        .cout(carry_out)
    );


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vector_addr <= 32'h0;
            int_valid <= 1'b0;
        end else begin
            // Check if any interrupt request is active
            if (int_req != 8'h0) begin
                // Use the address calculated by the CLA adder
                vector_addr <= calculated_addr;
                int_valid <= 1'b1;
            end else begin
                // No interrupt request active
                // vector_addr keeps its previous value
                int_valid <= 1'b0;
            end
        end
    end

endmodule