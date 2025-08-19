//SystemVerilog
// Submodule for a single core's IVMU logic
// Handles masking, priority encoding, vector address calculation,
// and registered IRQ/ACK logic for one core.
module CoreIVMU_Instance (
    input clk,
    input rst,
    input [15:0] irq_src,         // Global IRQ sources
    input core_ack,               // Acknowledge for this core
    input [15:0] core_mask_in,    // Mask for this core
    input [31:0] vector_base_in,  // Base address for this core
    output reg core_irq_out,      // IRQ flag for this core
    output reg [31:0] vec_addr_out // Vector address for this core
);

    // Wires for combinational logic
    wire [15:0] masked_irq;
    wire [3:0] msb_idx_w;
    wire [31:0] vec_addr_w;

    // Calculate masked IRQ: irq_src AND NOT core_mask
    assign masked_irq = irq_src & ~core_mask_in;

    // Priority encoder: Find the index of the most significant bit set in masked_irq
    // This determines the specific interrupt source within the masked interrupts.
    assign msb_idx_w =
        masked_irq[15] ? 4'd15 :
        masked_irq[14] ? 4'd14 :
        masked_irq[13] ? 4'd13 :
        masked_irq[12] ? 4'd12 :
        masked_irq[11] ? 4'd11 :
        masked_irq[10] ? 4'd10 :
        masked_irq[9]  ? 4'd9  :
        masked_irq[8]  ? 4'd8  :
        masked_irq[7]  ? 4'd7  :
        masked_irq[6]  ? 4'd6  :
        masked_irq[5]  ? 4'd5  :
        masked_irq[4]  ? 4'd4  :
        masked_irq[3]  ? 4'd3  :
        masked_irq[2]  ? 4'd2  :
        masked_irq[1]  ? 4'd1  :
        masked_irq[0]  ? 4'd0  :
        4'd0; // Default if no bit is set (should not happen if |masked_irq is true)

    // Calculate potential vector address based on base address and interrupt index
    // Shift index by 2 because vector addresses are word-aligned (32-bit words)
    assign vec_addr_w = vector_base_in + (msb_idx_w << 2);

    // Registered logic for core IRQ flag and vector address output
    // Updates happen on clock edge or reset
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset outputs
            core_irq_out <= 1'b0;
            vec_addr_out <= 32'h0;
        end else begin
            if (core_ack) begin
                // If core acknowledges the interrupt, clear the IRQ flag
                core_irq_out <= 1'b0;
            end else if (|masked_irq && !core_irq_out) begin
                // If there is a pending masked IRQ and the IRQ flag is not already set
                // Set the IRQ flag and update the vector address
                core_irq_out <= 1'b1;
                vec_addr_out <= vec_addr_w; // Load the pre-calculated vector address
            end
            // If no ACK and no new masked IRQ (or IRQ already set), outputs retain their values
        end
    end

endmodule


// Top level module for Multi-Core IVMU
// Instantiates per-core IVMU logic modules and manages global state like masks.
module MultiCoreIVMU (
    input clk,
    input rst,
    input [15:0] irq_src,         // Global IRQ sources
    input [1:0] core_sel,         // Core select for mask update
    input [3:0] core_ack,         // Acknowledge signals for each core (core0 to core3)
    output reg [31:0] vec_addr [0:3], // Vector address for each core (core0 to core3)
    output reg [3:0] core_irq         // IRQ flag for each core (core0 to core3)
);

    // Internal state arrays managed at the top level
    // vector_base is typically static after initialization
    reg [31:0] vector_base [0:3];
    // core_mask can be updated dynamically per core
    reg [15:0] core_mask [0:3];

    // Wires to connect outputs from submodule instances
    // These wires hold the calculated values from each core instance
    wire [3:0] core_irq_w;
    wire [31:0] vec_addr_w [0:3];

    integer i; // Loop variable for sequential blocks

    // Initialize vector base addresses and default core masks
    // Using reset logic for synthesizable initialization
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Initialize per-core state arrays on reset
            for (i = 0; i < 4; i = i + 1) begin
                vector_base[i] <= 32'h8000_0000 + (i << 8); // Example base addresses
                core_mask[i] <= 16'hFFFF >> i;           // Example initial masks
            end
            // Reset outputs (also registered in the instance module, but good practice here too)
            core_irq <= 4'h0;
            for (i = 0; i < 4; i = i + 1) begin
                vec_addr[i] <= 32'h0;
            end
        end else begin
            // Logic to update a specific core's mask based on core_sel and irq_src
            // This happens when core_sel is non-zero, indicating a mask update request
            if (|core_sel) begin
                // core_sel[1:0] selects which core's mask to update (0-3)
                core_mask[core_sel] <= irq_src; // Update the selected core's mask with current irq_src
            end

            // Register the outputs from the submodule instances to the top-level output registers
            core_irq <= core_irq_w;
            for (i = 0; i < 4; i = i + 1) begin
                vec_addr[i] <= vec_addr_w[i];
            end
        end
    end

    // Instantiate 4 instances of the per-core IVMU logic submodule
    // Each instance handles the logic for one specific core
    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin: gen_core_ivmu
            CoreIVMU_Instance core_ivmu_inst (
                .clk(clk),
                .rst(rst),
                .irq_src(irq_src),              // Pass global IRQ source to all instances
                .core_ack(core_ack[g]),         // Pass the specific core's ACK bit
                .core_mask_in(core_mask[g]),    // Pass the specific core's mask from the array
                .vector_base_in(vector_base[g]),// Pass the specific core's base address from the array
                .core_irq_out(core_irq_w[g]),   // Connect instance output to the wire array
                .vec_addr_out(vec_addr_w[g])    // Connect instance output to the wire array
            );
        end
    endgenerate

endmodule