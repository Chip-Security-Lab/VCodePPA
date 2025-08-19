//SystemVerilog
module TwoLevelIVMU_pipelined (
    input wire clock, reset,
    input wire [31:0] irq_lines,
    input wire [31:0] group_priority_flat, // Kept for compatibility, not used by original logic
    output reg [31:0] handler_addr,
    output reg irq_active
);

    // Vector table memory
    reg [31:0] vector_table [0:31];
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            vector_table[i] = 32'hFFF8_0000 + (i << 4);
    end

    // --- Pipeline Registers ---
    // Stage 0 Outputs -> Stage 1 Inputs (New stage after splitting priority encoder)
    reg [4:0] irq_index_part1_reg; // Index for lines 0-15
    reg any_pending_part1_reg;    // Pending flag for lines 0-15
    reg [4:0] irq_index_part2_reg; // Index for lines 16-31
    reg any_pending_part2_reg;    // Pending flag for lines 16-31
    reg valid_stage0_reg;         // Valid signal for data entering Stage 1

    // Stage 1 Outputs -> Stage 2 Inputs (Combines results from Stage 0)
    reg [4:0] irq_index_stage1_reg; // Final prioritized index after Stage 1
    reg any_pending_stage1_reg;    // Final pending flag after Stage 1
    reg valid_stage1_reg;         // Valid signal for data entering Stage 2

    // --- Stage 0: Partial Priority Encoding (Lines 0-15 and 16-31) ---
    wire [4:0] irq_index_part1;
    wire any_pending_part1;
    wire [4:0] irq_index_part2;
    wire any_pending_part2;
    wire valid_stage0_comb;

    // Priority encode lines 0-15
    assign any_pending_part1 = |irq_lines[15:0];
    assign irq_index_part1 =
        irq_lines[3] ? 5'd3 :
        irq_lines[2] ? 5'd2 :
        irq_lines[1] ? 5'd1 :
        irq_lines[0] ? 5'd0 :
        irq_lines[7] ? 5'd7 :
        irq_lines[6] ? 5'd6 :
        irq_lines[5] ? 5'd5 :
        irq_lines[4] ? 5'd4 :
        irq_lines[11] ? 5'd11 :
        irq_lines[10] ? 5'd10 :
        irq_lines[9] ? 5'd9 :
        irq_lines[8] ? 5'd8 :
        irq_lines[15] ? 5'd15 :
        irq_lines[14] ? 5'd14 :
        irq_lines[13] ? 5'd13 :
        irq_lines[12] ? 5'd12 :
        5'd0; // Default

    // Priority encode lines 16-31
    assign any_pending_part2 = |irq_lines[31:16];
    assign irq_index_part2 =
        irq_lines[19] ? 5'd19 :
        irq_lines[18] ? 5'd18 :
        irq_lines[17] ? 5'd17 :
        irq_lines[16] ? 5'd16 :
        irq_lines[23] ? 5'd23 :
        irq_lines[22] ? 5'd22 :
        irq_lines[21] ? 5'd21 :
        irq_lines[20] ? 5'd20 :
        irq_lines[27] ? 5'd27 :
        irq_lines[26] ? 5'd26 :
        irq_lines[25] ? 5'd25 :
        irq_lines[24] ? 5'd24 :
        irq_lines[31] ? 5'd31 :
        irq_lines[30] ? 5'd30 :
        irq_lines[29] ? 5'd29 :
        irq_lines[28] ? 5'd28 :
        5'd0; // Default

    assign valid_stage0_comb = any_pending_part1 | any_pending_part2;

    // Stage 0 Sequential Logic: Registering Stage 0 outputs
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            irq_index_part1_reg <= 5'd0;
            any_pending_part1_reg <= 1'b0;
            irq_index_part2_reg <= 5'd0;
            any_pending_part2_reg <= 1'b0;
            valid_stage0_reg <= 1'b0;
        end else begin
            irq_index_part1_reg <= irq_index_part1;
            any_pending_part1_reg <= any_pending_part1;
            irq_index_part2_reg <= irq_index_part2;
            any_pending_part2_reg <= any_pending_part2;
            valid_stage0_reg <= valid_stage0_comb;
        end
    end

    // --- Stage 1: Combine Priority Results ---
    wire [4:0] irq_index_stage1;
    wire any_pending_stage1;
    wire valid_stage1_comb;

    // Prioritize part1 over part2
    assign any_pending_stage1 = any_pending_part1_reg | any_pending_part2_reg;
    assign irq_index_stage1 = any_pending_part1_reg ? irq_index_part1_reg : irq_index_part2_reg; // If neither is pending, uses default 0 from part2_reg

    assign valid_stage1_comb = valid_stage0_reg; // Propagate valid signal

    // Stage 1 Sequential Logic: Registering Stage 1 outputs
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            irq_index_stage1_reg <= 5'd0;
            any_pending_stage1_reg <= 1'b0;
            valid_stage1_reg <= 1'b0;
        end else begin
            irq_index_stage1_reg <= irq_index_stage1;
            any_pending_stage1_reg <= any_pending_stage1;
            valid_stage1_reg <= valid_stage1_comb;
        end
    end

    // --- Stage 2: Address Lookup ---
    wire [31:0] handler_addr_stage2;
    wire irq_active_stage2;

    // Combinational logic for Stage 2
    // Read the vector table using the registered index from Stage 1
    // This read is always performed, but the output is only used if valid_stage1_reg is true
    assign handler_addr_stage2 = vector_table[irq_index_stage1_reg];

    // The active signal for Stage 2 is the pending status from Stage 1
    assign irq_active_stage2 = any_pending_stage1_reg;

    // Stage 2 Sequential Logic: Registering Stage 2 outputs (Final Output)
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            handler_addr <= 32'd0;
            irq_active <= 1'b0;
        end else begin
            // If data from Stage 1 was valid, register the Stage 2 results
            if (valid_stage1_reg) begin
                handler_addr <= handler_addr_stage2;
                irq_active <= irq_active_stage2; // This will be 1 if any_pending_stage1_reg was 1
            end else begin
                // If data from Stage 1 was not valid, the output should be inactive
                handler_addr <= 32'd0;
                irq_active <= 1'b0;
            end
        end
    end

endmodule