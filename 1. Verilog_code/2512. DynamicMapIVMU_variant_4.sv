//SystemVerilog
module DynamicMapIVMU (
    input clk, reset,
    input [7:0] irq,
    input [2:0] map_idx,
    input [2:0] map_irq_num,
    input map_update,
    output reg [31:0] irq_vector,
    output reg irq_req // Converted from irq_valid
);

    localparam [31:0] VECTOR_BASE = 32'hA000_0000;

    reg [2:0] irq_map [0:7]; // Maps IRQ number to vector index
    integer i; // Loop variable for initialization and priority logic

    // Combinatorial logic to calculate the potential next vector
    reg [31:0] calculated_irq_vector;
    always @(*) begin
        calculated_irq_vector = VECTOR_BASE; // Default value
        // Priority encoding loop (synthesizes to priority logic)
        // Iterates from highest priority IRQ (index 7) down to lowest (index 0)
        for (i = 7; i >= 0; i = i - 1) begin
            if (irq[i]) begin
                // If IRQ[i] is asserted, calculate the vector using its mapped index
                calculated_irq_vector = VECTOR_BASE + (irq_map[i] << 4);
                // Since we iterate from high to low, the first asserted IRQ determines the vector
            end
        end
    end

    // Registered block for irq_map updates
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize irq_map on reset
            for (i = 0; i < 8; i = i + 1) begin
                irq_map[i] <= i[2:0]; // Default mapping: IRQ i maps to vector index i
            end
        end else if (map_update) begin
            // Update a specific irq_map entry if map_update is asserted
            irq_map[map_idx] <= map_irq_num;
        end
        // If not reset and not map_update, irq_map retains its value
    end

    // Registered block for irq_req output (converted from irq_valid)
    // This signal indicates a request is pending/data is available
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            irq_req <= 1'b0; // Reset irq_req
        end else if (~map_update) begin
            // Update irq_req only when map_update is not asserted
            // irq_req is true if any IRQ is asserted
            irq_req <= |irq;
        end
        // If map_update is asserted, irq_req retains its value
    end

    // Registered block for irq_vector output
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            irq_vector <= 32'b0; // Reset irq_vector to a default value
        end else if (~map_update) begin
            // Update irq_vector only when map_update is not asserted
            // Use the combinatorially calculated vector
            irq_vector <= calculated_irq_vector;
        end
        // If map_update is asserted, irq_vector retains its value
    end

endmodule