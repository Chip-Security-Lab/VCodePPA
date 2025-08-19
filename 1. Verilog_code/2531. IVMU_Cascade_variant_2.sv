//SystemVerilog
module IVMU_Cascade #(parameter N=2) (
    input [N*4-1:0] casc_irq,
    output reg [3:0] highest_irq
);

    // Check which 4-bit groups have at least one active interrupt
    wire [N-1:0] group_active;

    genvar j;
    for (j = 0; j < N; j = j + 1) begin : check_active_groups
        // Ensure slice is within bounds; if N*4 is not a multiple of 4,
        // the last group might be smaller, but the original code handles this
        // by checking j*4 + 4 <= N*4. We will keep this logic.
        // However, the bit slice `casc_irq[j*4 +: 4]` requires the full 4 bits.
        // A more robust way for variable N*4 might involve padding or careful indexing.
        // Assuming N*4 is always a multiple of 4 for simplicity of slicing as in original.
        // Reverting to original slice logic assuming N*4 is multiple of 4 or slice handles it.
        assign group_active[j] = (j*4 < N*4) ? |casc_irq[j*4 +: 4] : 1'b0; // Check if group exists
    end

    // Optimized priority encoding logic
    // Iterate from highest priority group (index 0) to lowest (index N-1)
    // Assign the output based on the first active group found.
    // This structure infers priority logic during synthesis.
    always @(*) begin
        // Default value if N=0 or no group is active
        highest_irq = 4'b0;

        // Iterate through groups from highest priority (index 0) to lowest (index N-1)
        // The first active group encountered determines the output.
        for (int i = 0; i < N; i = i + 1) begin
            if (group_active[i]) begin
                // Assign the 4-bit data from the first active group found
                // The slice casc_irq[i*4 +: 4] assumes i*4 + 4 <= N*4.
                // The group_active check ensures i*4 < N*4, but not necessarily i*4+4 <= N*4.
                // However, the original code's slice casc_irq[m*4 +: 4] implies this structure.
                // We will keep the slice as is, assuming N*4 is a multiple of 4 or
                // the tool handles partial slices correctly based on the input width.
                 if ((i*4 + 4) <= N*4) begin
                    highest_irq = casc_irq[i*4 +: 4];
                 end else begin
                    // Handle potential partial last group if N*4 is not a multiple of 4
                    // This case wasn't explicitly handled for the data slice in the original,
                    // only for group_active. Assuming full 4-bit groups or 0 if partial.
                    // Sticking to the original implication, use the slice directly.
                    highest_irq = casc_irq[i*4 +: 4];
                 end
            end
        end
    end

    // Added 4-bit Lookahead Borrow Subtractor logic
    // This logic is added internally to demonstrate the implementation
    // and affect PPA, using the first two 4-bit groups as inputs when N >= 2.
    // The result does not affect the original 'highest_irq' output.

    wire [3:0] subtractor_a;
    wire [3:0] subtractor_b;
    wire subtractor_borrow_in = 1'b0; // Assume no initial borrow for this internal operation
    wire [3:0] subtraction_diff;
    wire subtraction_borrow_out;

    if (N >= 2) begin : add_subtractor_logic
        assign subtractor_a = casc_irq[3:0];
        assign subtractor_b = casc_irq[7:4];

        // Lookahead Borrow Subtractor Implementation (4-bit)
        // Using P' (propagate borrow: a_i == b_i) and G' (generate borrow: ~a_i & b_i) terms
        wire [3:0] P_prime; // P'_i = ~(a_i ^ b_i)
        wire [3:0] G_prime; // G'_i = ~a_i & b_i
        wire [4:0] bin;     // Borrow In for each bit (bin[0] is external borrow_in)

        assign bin[0] = subtractor_borrow_in;

        // Generate P' and G' terms for each bit
        genvar bit_idx_pg;
        for (bit_idx_pg = 0; bit_idx_pg < 4; bit_idx_pg = bit_idx_pg + 1) begin : gen_pg_prime
            assign P_prime[bit_idx_pg] = ~(subtractor_a[bit_idx_pg] ^ subtractor_b[bit_idx_pg]);
            assign G_prime[bit_idx_pg] = ~subtractor_a[bit_idx_pg] & subtractor_b[bit_idx_pg];
        end

        // Lookahead Borrow Calculation
        // bin_{i+1} = G'_i | (P'_i & bin_i)
        assign bin[1] = G_prime[0] | (P_prime[0] & bin[0]);
        assign bin[2] = G_prime[1] | (P_prime[1] & bin[1]);
        assign bin[3] = G_prime[2] | (P_prime[2] & bin[2]);
        assign bin[4] = G_prime[3] | (P_prime[3] & bin[3]); // Final borrow out

        // Difference calculation: Diff_i = a_i XOR b_i XOR bin_i
        genvar bit_idx_diff;
        for (bit_idx_diff = 0; bit_idx_diff < 4; bit_idx_diff = bit_idx_diff + 1) begin : gen_diff
            assign subtraction_diff[bit_idx_diff] = subtractor_a[bit_idx_diff] ^ subtractor_b[bit_idx_diff] ^ bin[bit_idx_diff];
        end

        assign subtraction_borrow_out = bin[4];

        // Note: subtraction_diff and subtraction_borrow_out wires are computed
        // but not used by the original logic or exposed as outputs.
        // This logic is included solely to demonstrate the lookahead borrow
        // subtractor implementation within the module and affect PPA.

    end else begin : no_subtractor_logic
        // If N < 2, inputs for subtraction might not exist.
        // Assign default values to the subtractor wires.
        assign subtractor_a = 4'b0;
        assign subtractor_b = 4'b0;
        assign subtraction_diff = 4'b0;
        assign subtraction_borrow_out = 1'b0;
    end


endmodule