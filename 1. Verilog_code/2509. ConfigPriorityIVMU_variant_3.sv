//SystemVerilog
module ConfigPriorityIVMU (
    input clk, reset,
    input [7:0] irq_in,
    input [2:0] priority_cfg [0:7],
    input update_pri,
    output reg [31:0] isr_addr,
    output reg irq_out
);
    // Internal memories/registers
    reg [31:0] vector_table [0:7];
    reg [2:0] priorities [0:7];
    reg [2:0] highest_pri; // Internal register, not output
    reg [2:0] highest_idx; // Internal register, not output

    // Initialization of vector_table
    integer i; // Use integer for loop variables

    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            vector_table[i] = 32'h7000_0000 + (i * 64);
        end
    end

    // --- Pipeline Stage 0 (Combinatorial) ---
    // Candidate pairs {priority, index} for active interrupts
    // Use {3'h7, 3'h7} as an indicator for inactive interrupts (highest priority value + highest index)
    wire [5:0] candidate [0:7];

    genvar gi;
    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : gen_candidates
            // If irq_in[gi] is high, candidate is {priorities[gi], gi}.
            // If irq_in[gi] is low, candidate is {3'h7, 3'h7} (effectively inactive).
            assign candidate[gi] = irq_in[gi] ? {priorities[gi], gi[2:0]} : {3'h7, 3'h7};
        end
    endgenerate

    // --- Pipeline Stage 1 (Combinatorial) ---
    // First level of comparators
    wire [5:0] min_cand_0_1_s1 = (candidate[0] < candidate[1]) ? candidate[0] : candidate[1];
    wire [5:0] min_cand_2_3_s1 = (candidate[2] < candidate[3]) ? candidate[2] : candidate[3];
    wire [5:0] min_cand_4_5_s1 = (candidate[4] < candidate[5]) ? candidate[4] : candidate[5];
    wire [5:0] min_cand_6_7_s1 = (candidate[6] < candidate[7]) ? candidate[6] : candidate[7];

    // --- Pipeline Stage 2 (Registered) ---
    reg [5:0] min_cand_0_1_p1, min_cand_2_3_p1, min_cand_4_5_p1, min_cand_6_7_p1;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            min_cand_0_1_p1 <= {6{1'b0}};
            min_cand_2_3_p1 <= {6{1'b0}};
            min_cand_4_5_p1 <= {6{1'b0}};
            min_cand_6_7_p1 <= {6{1'b0}};
        end else begin
            min_cand_0_1_p1 <= min_cand_0_1_s1;
            min_cand_2_3_p1 <= min_cand_2_3_s1;
            min_cand_4_5_p1 <= min_cand_4_5_s1;
            min_cand_6_7_p1 <= min_cand_6_7_s1;
        end
    end

    // --- Pipeline Stage 3 (Combinatorial) ---
    // Second level of comparators (uses registered values from P1)
    wire [5:0] min_cand_0_3_s3 = (min_cand_0_1_p1 < min_cand_2_3_p1) ? min_cand_0_1_p1 : min_cand_2_3_p1;
    wire [5:0] min_cand_4_7_s3 = (min_cand_4_5_p1 < min_cand_6_7_p1) ? min_cand_4_5_p1 : min_cand_6_7_p1;

    // Final comparator
    wire [5:0] final_min_cand_s3 = (min_cand_0_3_s3 < min_cand_4_7_s3) ? min_cand_0_3_s3 : min_cand_4_7_s3;

    // Determine the winning interrupt details from the minimum candidate
    wire [2:0] winning_pri_s3 = final_min_cand_s3[5:3];
    wire [2:0] winning_idx_s3 = final_min_cand_s3[2:0];
    // An active IRQ is found if the winning priority is not the inactive marker (3'h7)
    wire active_irq_found_s3 = (winning_pri_s3 != 3'h7);

    // --- Pipeline Stage 4 (Registered) ---
    reg [2:0] winning_pri_p2, winning_idx_p2;
    reg active_irq_found_p2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            winning_pri_p2 <= {3{1'b0}};
            winning_idx_p2 <= {3{1'b0}};
            active_irq_found_p2 <= 1'b0;
        end else begin
            winning_pri_p2 <= winning_pri_s3;
            winning_idx_p2 <= winning_idx_s3;
            active_irq_found_p2 <= active_irq_found_s3;
        end
    end

    // --- Pipeline Stage 5 (Registered - Main State Logic) ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize priorities on reset (default priority = index)
            for (i = 0; i < 8; i = i + 1) priorities[i] <= i[2:0];
            irq_out <= 1'b0;
            highest_pri <= 3'h7; // Reset internal state to 'no IRQ'
            highest_idx <= 3'h0; // Reset internal state
            // isr_addr retains value on reset, matching original code behavior.
        end else if (update_pri) begin
            // Update priorities from configuration input
            for (i = 0; i < 8; i = i + 1) priorities[i] <= priority_cfg[i];
            // irq_out, isr_addr, highest_pri, highest_idx retain values, matching original code behavior.
        end else begin // Not reset and not update_pri: perform interrupt arbitration
            // Use pipelined results from Stage 4
            irq_out <= active_irq_found_p2; // Assert irq_out if an active IRQ is found

            if (active_irq_found_p2) begin
                // Update registered state based on the winning interrupt (from pipelined result)
                // Note: vector_table lookup is combinatorial based on the *registered* index
                isr_addr <= vector_table[winning_idx_p2];
                highest_pri <= winning_pri_p2;
                highest_idx <= winning_idx_p2;
            end else begin
                // No active IRQ found (from pipelined result).
                // isr_addr retains its value, matching original code behavior.
                // highest_pri and highest_idx are reset to their initial 'no IRQ' state.
                highest_pri <= 3'h7;
                highest_idx <= 3'h0;
            end
        end
    end

endmodule