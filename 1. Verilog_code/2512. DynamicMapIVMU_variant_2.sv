//SystemVerilog
// SystemVerilog
module DynamicMapIVMU (
    input clk, reset,
    input [7:0] irq,
    input [2:0] map_idx,
    input [2:0] map_irq_num,
    input map_update,
    output reg [31:0] irq_vector,
    output reg irq_valid
);
    // Internal storage for irq_map and vector_base
    reg [2:0] irq_map [0:7]; // Maps IRQ number to vector index
    reg [31:0] vector_base_reg; // Registered version of vector_base

    // Stage 1 pipeline registers (results from IRQ lookup)
    reg [2:0] selected_irq_idx_r;
    reg irq_hit_r;
    reg irq_valid_stage1; // Valid signal indication from Stage 1

    // Loop variable (local to always blocks)
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize state
            vector_base_reg <= 32'hA000_0000;
            for (i = 0; i < 8; i = i + 1) irq_map[i] <= i[2:0];
            selected_irq_idx_r <= 0;
            irq_hit_r <= 0;
            irq_valid_stage1 <= 0;
            irq_vector <= 32'hA000_0000; // Initialize output vector
            irq_valid <= 0; // Initialize output valid
        end else begin
            // Handle map update (State Update)
            if (map_update) begin
                irq_map[map_idx] <= map_irq_num;
                // During map update, hold pipeline registers and outputs
                // selected_irq_idx_r <= selected_irq_idx_r; // Implied
                // irq_hit_r <= irq_hit_r; // Implied
                // irq_valid_stage1 <= irq_valid_stage1; // Implied
                // irq_vector <= irq_vector; // Implied
                // irq_valid <= irq_valid; // Implied
            end else begin
                // Stage 1: Combinational lookup from irq and irq_map
                // This logic determines the input to the pipeline registers
                reg [2:0] next_selected_irq_idx;
                reg next_irq_hit;

                next_irq_hit = 0;
                next_selected_irq_idx = 0;
                // Loop for priority encoding/lookup
                for (i = 7; i >= 0; i = i - 1) begin
                    if (irq[i]) begin
                        next_selected_irq_idx = irq_map[i];
                        next_irq_hit = 1;
                    end
                end

                // Register results for Stage 2
                selected_irq_idx_r <= next_selected_irq_idx;
                irq_hit_r <= next_irq_hit;
                irq_valid_stage1 <= |irq; // Pipeline the irq_valid condition

                // Stage 2: Calculation and output
                // This stage uses registered values from the end of the previous cycle
                if (irq_hit_r) begin
                    irq_vector <= vector_base_reg + (selected_irq_idx_r << 4);
                end else begin
                    // If no IRQ was hit in the previous cycle, output vector_base
                    irq_vector <= vector_base_reg;
                end
                irq_valid <= irq_valid_stage1; // Output the pipelined valid signal
            end
        end
    end
endmodule