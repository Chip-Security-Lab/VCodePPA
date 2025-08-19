//SystemVerilog
module TwoLevelIVMU_pipelined (
    input wire clock, reset,
    input wire [31:0] irq_lines,
    input wire [31:0] group_priority_flat, // This input is not used in this pipelined version, based on original logic's fixed priority
    output wire [31:0] handler_addr,
    output wire irq_active
);

    // --- Stage 1: Identify pending groups and find the highest priority group ---

    // Combinational logic for Stage 1
    wire [7:0] group_pending_s1_comb;
    wire [3:0] winning_group_index_s1_comb;
    wire group_found_s1_comb;

    // Calculate group_pending (combinational)
    genvar g;
    generate
        for (g = 0; g < 8; g = g + 1) begin: group_gen_s1
            assign group_pending_s1_comb[g] = |irq_lines[g*4+3:g*4];
        end
    endgenerate

    // Find winning group (fixed priority: group 0 > 1 > ... > 7)
    assign {group_found_s1_comb, winning_group_index_s1_comb} =
        group_pending_s1_comb[0] ? {1'b1, 4'd0} :
        group_pending_s1_comb[1] ? {1'b1, 4'd1} :
        group_pending_s1_comb[2] ? {1'b1, 4'd2} :
        group_pending_s1_comb[3] ? {1'b1, 4'd3} :
        group_pending_s1_comb[4] ? {1'b1, 4'd4} :
        group_pending_s1_comb[5] ? {1'b1, 4'd5} :
        group_pending_s1_comb[6] ? {1'b1, 4'd6} :
        group_pending_s1_comb[7] ? {1'b1, 4'd7} :
        {1'b0, 4'd0}; // Default if no group pending

    // Pipeline registers between Stage 1 and Stage 2
    reg [3:0] winning_group_index_s2;
    reg group_found_s2;
    reg [31:0] irq_lines_s2; // Pass irq_lines snapshot to Stage 2

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            winning_group_index_s2 <= 0;
            group_found_s2 <= 0;
            irq_lines_s2 <= 0;
        end else begin
            winning_group_index_s2 <= winning_group_index_s1_comb;
            group_found_s2 <= group_found_s1_comb;
            irq_lines_s2 <= irq_lines; // Capture input for next stage
        end
    end

    // --- Stage 2: Find winning line within the group and calculate interrupt index ---

    // Combinational logic for Stage 2
    wire [4:0] interrupt_index_s2_comb; // 0-31 needs 5 bits
    wire interrupt_found_s2_comb;
    wire [3:0] winning_line_index_s2_comb;

    // Find winning line within the winning group (fixed priority: line 3 > 2 > 1 > 0)
    assign {interrupt_found_s2_comb, winning_line_index_s2_comb} =
        group_found_s2 ? ( // Only proceed if a group was found in Stage 1
            irq_lines_s2[winning_group_index_s2*4+3] ? {1'b1, 4'd3} :
            irq_lines_s2[winning_group_index_s2*4+2] ? {1'b1, 4'd2} :
            irq_lines_s2[winning_group_index_s2*4+1] ? {1'b1, 4'd1} :
            irq_lines_s2[winning_group_index_s2*4+0] ? {1'b1, 4'd0} :
            {1'b0, 4'd0} // Should not happen if group_found_s2 is true and irq_lines_s2 matches group_pending_s1_comb
        ) : {1'b0, 4'd0};

    // Calculate the overall interrupt index (group * 4 + line)
    assign interrupt_index_s2_comb = (winning_group_index_s2 << 2) | winning_line_index_s2_comb;

    // Pipeline registers between Stage 2 and Stage 3
    reg [4:0] interrupt_index_s3;
    reg interrupt_found_s3;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            interrupt_index_s3 <= 0;
            interrupt_found_s3 <= 0;
        end else begin
            interrupt_index_s3 <= interrupt_index_s2_comb;
            interrupt_found_s3 <= interrupt_found_s2_comb;
        end
    end

    // --- Stage 3: Handler Address Calculation and Output ---

    // Combinational logic for Stage 3 (Handler address calculation using Carry-Select Adder)
    wire [31:0] handler_addr_s3_comb;

    // Base address constant
    localparam [31:0] BASE_ADDRESS = 32'hFFF8_0000;
    // Offset calculation: interrupt_index_s3 * 16 (i.e., interrupt_index_s3 << 4)
    // interrupt_index_s3 is 5 bits [4:0]
    wire [31:0] offset = { {27{1'b0}}, interrupt_index_s3, 4'b0 };

    // Instantiate the 32-bit Carry-Select Adder
    carry_select_adder_32 addr_calculator (
        .a(BASE_ADDRESS),
        .b(offset),
        .cin(1'b0), // Carry-in is 0 for this addition
        .sum(handler_addr_s3_comb),
        .cout() // Carry-out is not used
    );


    // Pipeline registers for final output
    reg [31:0] handler_addr_reg;
    reg irq_active_reg;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            handler_addr_reg <= 0;
            irq_active_reg <= 0;
        end else begin
            // Update output registers only if Stage 2 found a valid interrupt
            if (interrupt_found_s3) begin
                handler_addr_reg <= handler_addr_s3_comb; // Use the calculated result
                irq_active_reg <= 1;
            end else begin
                // If no interrupt was found in Stage 2, clear output active signal
                handler_addr_reg <= 0; // Reset handler_addr as well, matching original behavior
                irq_active_reg <= 0;
            end
        end
    end

    // Assign final outputs from Stage 3 registers
    assign handler_addr = handler_addr_reg;
    assign irq_active = irq_active_reg;

endmodule

// 8-bit Ripple-Carry Adder (Helper module for Carry-Select Adder)
module ripple_adder_8 (
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [8:0] carry;
    assign carry[0] = cin;
    genvar j;
    generate
        for (j = 0; j < 8; j = j + 1) begin: bit_adder
            wire p = a[j] ^ b[j]; // Propagate
            wire g = a[j] & b[j]; // Generate
            assign sum[j] = p ^ carry[j];
            assign carry[j+1] = g | (p & carry[j]);
        end
    endgenerate
    assign cout = carry[8];
endmodule

// 32-bit Carry-Select Adder (using 8-bit blocks)
module carry_select_adder_32 (
    input [31:0] a,
    input [31:0] b,
    input cin,
    output [31:0] sum,
    output cout
);

    // Define block size
    parameter BLOCK_SIZE = 8;
    localparam NUM_BLOCKS = 32 / BLOCK_SIZE; // Should be 4

    // Wires for parallel sums and carries
    wire [BLOCK_SIZE-1:0] sum_cin0 [0:NUM_BLOCKS-1];
    wire [BLOCK_SIZE-1:0] sum_cin1 [0:NUM_BLOCKS-1];
    wire cout_cin0 [0:NUM_BLOCKS-1];
    wire cout_cin1 [0:NUM_BLOCKS-1];

    // Wires for actual carries between blocks
    wire actual_carry [0:NUM_BLOCKS]; // actual_carry[i] is cin for block i, cout from block i-1
    assign actual_carry[0] = cin; // Overall carry-in for the first block

    genvar i;
    generate
        for (i = 0; i < NUM_BLOCKS; i = i + 1) begin: block_gen
            localparam START_BIT = i * BLOCK_SIZE;
            localparam END_BIT = START_BIT + BLOCK_SIZE - 1;

            // Instantiate two adders for each block (cin=0 and cin=1)
            ripple_adder_8 adder_cin0 (
                .a(a[END_BIT:START_BIT]),
                .b(b[END_BIT:START_BIT]),
                .cin(1'b0),
                .sum(sum_cin0[i]),
                .cout(cout_cin0[i])
            );

            ripple_adder_8 adder_cin1 (
                .a(a[END_BIT:START_BIT]),
                .b(b[END_BIT:START_BIT]),
                .cin(1'b1),
                .sum(sum_cin1[i]),
                .cout(cout_cin1[i])
            );

            // Select the correct sum and carry based on the actual carry from the previous block
            assign sum[END_BIT:START_BIT] = (actual_carry[i] == 1'b0) ? sum_cin0[i] : sum_cin1[i];
            assign actual_carry[i+1] = (actual_carry[i] == 1'b0) ? cout_cin0[i] : cout_cin1[i];
        end
    endgenerate

    assign cout = actual_carry[NUM_BLOCKS]; // Overall carry-out

endmodule