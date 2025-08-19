//SystemVerilog
module MultiCoreIVMU (
    input clk, rst,
    input [15:0] irq_src,
    input [1:0] core_sel,
    input [1:0] core_ack,
    output reg [31:0] vec_addr [0:3],
    output reg [3:0] core_irq
);
    reg [31:0] vector_base [0:3];
    reg [15:0] core_mask [0:3];
    wire [15:0] masked_irq [0:3];
    integer i, j;

    initial begin
        for (i = 0; i < 4; i = i + 1) begin
            vector_base[i] = 32'h8000_0000 + (i << 8);
            core_mask[i] = 16'hFFFF >> i; // Different mask per core
        end
    end

    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin: gen_masks
            assign masked_irq[g] = irq_src & ~core_mask[g];
        end
    endgenerate

    always @(posedge clk or posedge rst) begin
        reg [1:0] core_state_i; // Temporary variable to determine state for core i

        if (rst) begin
            core_irq <= 4'h0;
            for (i = 0; i < 4; i = i + 1) vec_addr[i] <= 0;
        end else begin
            // Update core_mask based on core_sel
            if (|core_sel) begin
                 core_mask[core_sel] <= irq_src;
            end

            // Loop through each core to update its state and outputs
            for (i = 0; i < 4; i = i + 1) begin
                // Determine the state based on prioritized conditions for core i
                // State 2'b10: Acknowledge (highest priority)
                // State 2'b01: New IRQ (second priority, only if not acknowledged)
                // State 2'b00: Idle/No change (neither condition met)
                if (core_ack[i]) begin
                    core_state_i = 2'b10; // State: Acknowledge
                end else if (|masked_irq[i] && !core_irq[i]) begin
                    core_state_i = 2'b01; // State: New IRQ
                end else begin
                    core_state_i = 2'b00; // State: Idle/No change
                end

                // Use a case statement based on the determined state
                case (core_state_i)
                    2'b10: begin // State: Acknowledge (core_ack[i] is true)
                        core_irq[i] <= 0;
                        // vec_addr[i] remains unchanged as per original logic
                    end
                    2'b01: begin // State: New IRQ (core_ack[i] is false AND |masked_irq[i] && !core_irq[i] is true)
                        core_irq[i] <= 1;
                        // Calculate vec_addr[i] based on the lowest set bit in masked_irq[i]
                        // The original loop structure implements this lowest-bit-priority:
                        for (j = 15; j >= 0; j = j - 1) begin
                            if (masked_irq[i][j])
                                vec_addr[i] <= vector_base[i] + (j << 2);
                        end
                    end
                    2'b00: begin // State: Idle/No change (Neither condition is true)
                        // No assignments in this case, implies no change to core_irq[i] or vec_addr[i]
                    end
                    default: begin
                        // Should not reach here with the defined states 2'b00, 2'b01, 2'b10
                        // No assignments
                    end
                endcase
            end
        end
    end
endmodule