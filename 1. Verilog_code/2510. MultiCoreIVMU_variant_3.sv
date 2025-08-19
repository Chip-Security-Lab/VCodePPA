//SystemVerilog
module MultiCoreIVMU_pipelined (
    input clk, rst,
    input [15:0] irq_src,
    input [1:0] core_sel,
    input [1:0] core_ack,
    output reg [31:0] vec_addr [0:3],
    output reg [3:0] core_irq
);
    // State registers (updated synchronously)
    reg [31:0] vector_base [0:3];
    reg [15:0] core_mask [0:3];

    // Pipeline Stage 1 Registers (Input Stage)
    reg [15:0] irq_src_s1;
    reg [1:0] core_sel_s1;
    reg [1:0] core_ack_s1;
    reg valid_s1;

    // Combinatorial logic outputs for Stage 1 -> Stage 2
    // These calculate based on Stage 1 inputs and state registers
    wire [15:0] masked_irq_comb_s1 [0:3];
    wire [3:0] hsb_idx_comb_s1 [0:3];
    wire any_masked_irq_comb_s1 [0:3];
    wire [31:0] vec_addr_next_val_comb_s1 [0:3];

    // Pipeline Stage 2 Registers (Execute Stage)
    // Registers results from Stage 1 combinatorial logic and necessary Stage 1 inputs
    reg [0:3] any_masked_irq_s2;
    reg [31:0] vec_addr_next_val_s2 [0:3];
    reg [1:0] core_ack_s1_s2; // core_ack passed from Stage 1
    reg [1:0] core_sel_s1_s2; // core_sel passed from Stage 1 (for core_mask update)
    reg [15:0] irq_src_s1_s2; // irq_src passed from Stage 1 (for core_mask update)
    reg valid_s2;

    integer i;
    genvar g;

    // Combinatorial logic for Stage 1 -> Stage 2
    // Uses Stage 1 registered inputs (irq_src_s1) and state registers (core_mask, vector_base)
    generate
        for (g = 0; g < 4; g = g + 1) begin: gen_stage1_comb
            // Masking
            assign masked_irq_comb_s1[g] = irq_src_s1 & ~core_mask[g];

            // Calculate if any bit is set
            assign any_masked_irq_comb_s1[g] = |masked_irq_comb_s1[g];

            // Calculate highest set bit index (priority encoder)
            assign hsb_idx_comb_s1[g] = masked_irq_comb_s1[g][15] ? 4'd15 :
                                        masked_irq_comb_s1[g][14] ? 4'd14 :
                                        masked_irq_comb_s1[g][13] ? 4'd13 :
                                        masked_irq_comb_s1[g][12] ? 4'd12 :
                                        masked_irq_comb_s1[g][11] ? 4'd11 :
                                        masked_irq_comb_s1[g][10] ? 4'd10 :
                                        masked_irq_comb_s1[g][9]  ? 4'd9  :
                                        masked_irq_comb_s1[g][8]  ? 4'd8  :
                                        masked_irq_comb_s1[g][7]  ? 4'd7  :
                                        masked_irq_comb_s1[g][6]  ? 4'd6  :
                                        masked_irq_comb_s1[g][5]  ? 4'd5  :
                                        masked_irq_comb_s1[g][4]  ? 4'd4  :
                                        masked_irq_comb_s1[g][3]  ? 4'd3  :
                                        masked_irq_comb_s1[g][2]  ? 4'd2  :
                                        masked_irq_comb_s1[g][1]  ? 4'd1  :
                                        masked_irq_comb_s1[g][0]  ? 4'd0  :
                                        4'd0;

            // Calculate the potential next vector address
            assign vec_addr_next_val_comb_s1[g] = vector_base[g] + (hsb_idx_comb_s1[g] << 2);
        end
    endgenerate

    // Synchronous logic for pipeline registers and state updates
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset pipeline registers
            irq_src_s1 <= 0;
            core_sel_s1 <= 0;
            core_ack_s1 <= 0;
            valid_s1 <= 0;

            any_masked_irq_s2 <= 0;
            core_ack_s1_s2 <= 0;
            core_sel_s1_s2 <= 0;
            irq_src_s1_s2 <= 0;
            valid_s2 <= 0;

            // Reset state registers and output registers
            core_irq <= 0;
            for (i = 0; i < 4; i = i + 1) begin
                vec_addr[i] <= 0;
                vec_addr_next_val_s2[i] <= 0; // Resetting S2 array register
                // Initialize state registers
                vector_base[i] <= 32'h8000_0000 + (i << 8);
                core_mask[i] <= 16'hFFFF >> i;
            end
        end else begin
            // Stage 1: Input Registration
            irq_src_s1 <= irq_src;
            core_sel_s1 <= core_sel;
            core_ack_s1 <= core_ack;
            valid_s1 <= 1'b1; // Assume input is always valid when not in reset

            // Stage 2: Register results from Stage 1 combinatorial logic and Stage 1 inputs
            if (valid_s1) begin
                for (i = 0; i < 4; i = i + 1) begin
                    any_masked_irq_s2[i] <= any_masked_irq_comb_s1[i];
                    vec_addr_next_val_s2[i] <= vec_addr_next_val_comb_s1[i];
                end
                core_ack_s1_s2 <= core_ack_s1;
                core_sel_s1_s2 <= core_sel_s1;
                irq_src_s1_s2 <= irq_src_s1;
                valid_s2 <= valid_s1;
            end else begin // Flush pipeline if previous stage was invalid (or on initial cycles)
                 for (i = 0; i < 4; i = i + 1) begin
                    any_masked_irq_s2[i] <= 0;
                    vec_addr_next_val_s2[i] <= 0;
                end
                core_ack_s1_s2 <= 0;
                core_sel_s1_s2 <= 0;
                irq_src_s1_s2 <= 0;
                valid_s2 <= 0;
            end


            // Update core_mask based on Stage 2 inputs (which were Stage 1 inputs in the previous cycle)
            // This uses the registered core_sel and irq_src from Stage 1
            if (valid_s2 && |core_sel_s1_s2) begin // Only update if Stage 2 inputs were valid and core_sel is non-zero
                case (core_sel_s1_s2)
                    2'b01: core_mask[0] <= irq_src_s1_s2;
                    2'b10: core_mask[1] <= irq_src_s1_s2;
                    2'b11: core_mask[2] <= irq_src_s1_s2;
                    2'b00: ; // Explicitly do nothing for 2'b00
                endcase
            end

            // Output Stage: Update core_irq and vec_addr based on Stage 2 registered values
            // This logic uses Stage 2 results (any_masked_irq_s2, vec_addr_next_val_s2)
            // and the Stage 2 registered core_ack (core_ack_s1_s2)
            if (valid_s2) begin
                for (i = 0; i < 4; i = i + 1) begin
                    if (core_ack_s1_s2[i]) begin
                        // Acknowledge clears the IRQ flag
                        core_irq[i] <= 0;
                        // vec_addr[i] holds its current value (no change)
                    end else if (any_masked_irq_s2[i] && !core_irq[i]) begin
                        // If there's a pending masked IRQ from Stage 1 (now in S2) and the core isn't already signaling IRQ
                        core_irq[i] <= 1; // Assert the IRQ flag
                        // Update vec_addr with the address corresponding to the highest priority pending IRQ from Stage 1
                        vec_addr[i] <= vec_addr_next_val_s2[i];
                    end
                    // Else (no ack AND (no pending masked IRQ OR core is already signaling IRQ))
                    // core_irq[i] holds its current value (1 if it was 1, 0 if it was 0)
                    // vec_addr[i] holds its current value
                end
            end
        end
    end

endmodule