//SystemVerilog
// SystemVerilog
module DynamicMapIVMU (
    input logic clk,
    input logic reset,
    input logic [7:0] irq,
    input logic [2:0] map_idx,
    input logic [2:0] map_irq_num,
    input logic map_update,
    output logic [31:0] irq_vector,
    output logic irq_req
);

    // Internal State Registers
    logic [31:0] vector_base;
    logic [2:0] irq_map [0:7]; // Maps IRQ number to vector index

    // Pipeline Registers (Stage 0 -> Stage 1)
    logic any_irq_active_q1;       // Registered flag: Is any IRQ active?
    logic [2:0] highest_irq_idx_q1;  // Registered index: Index of highest priority active IRQ

    // Pipeline Registers (Stage 1 -> Stage 2a)
    logic any_irq_active_q2;       // Registered flag: Pass-through from Stage 1
    logic [2:0] mapped_index_q2;     // Registered index: Mapped vector index from map lookup

    // Pipeline Registers (Stage 2a -> Stage 2b) - Added for pipelining Stage 2 logic
    logic any_irq_active_q2a;      // Registered flag: Pass-through from Stage 2a
    logic [31:0] shifted_index_q2a; // Registered shifted index value

    // --- Initialization and Map Update Logic ---
    integer i; // Loop variable for initialization/reset

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize vector base and default map
            vector_base <= 32'hA000_0000;
            for (i = 0; i < 8; i = i + 1) begin
                irq_map[i] <= i[2:0];
            end
        end else if (map_update) begin
            // Update map based on inputs
            irq_map[map_idx] <= map_irq_num;
        end
    end

    // --- Pipeline Stage 0: Priority Encoding & Any Active Detection ---
    // Combinational logic for Stage 0
    logic any_irq_active_s0;
    logic [2:0] highest_irq_idx_s0;

    assign any_irq_active_s0 = |irq;

    // Combinational Priority Encoder: Finds the index of the highest active IRQ
    assign highest_irq_idx_s0 =
        irq[7] ? 3'd7 :
        irq[6] ? 3'd6 :
        irq[5] ? 3'd5 :
        irq[4] ? 3'd4 :
        irq[3] ? 3'd3 :
        irq[2] ? 3'd2 :
        irq[1] ? 3'd1 :
                 3'd0; // Default value when no IRQ is active (only used if any_irq_active_s0 is true)

    // Register outputs of Stage 0 for Stage 1
    always @(posedge clk or posedge reset) begin
        if (reset || map_update) begin // Flush pipeline on reset or map update
            any_irq_active_q1 <= 1'b0;
            highest_irq_idx_q1 <= 3'b0;
        end else begin
            any_irq_active_q1 <= any_irq_active_s0;
            highest_irq_idx_q1 <= highest_irq_idx_s0;
        end
    end

    // --- Pipeline Stage 1: Map Lookup ---
    // Combinational logic for Stage 1
    logic [2:0] mapped_index_s1;

    // Combinational lookup from irq_map using the registered index from Stage 0
    // irq_map is a register array, so reading from it is combinational w.r.t the index
    assign mapped_index_s1 = irq_map[highest_irq_idx_q1];

    // Register outputs of Stage 1 for Stage 2a
    always @(posedge clk or posedge reset) begin
        if (reset || map_update) begin // Flush pipeline
            mapped_index_q2 <= 3'b0;
            any_irq_active_q2 <= 1'b0; // Pass through the 'any active' state
        end else begin
            mapped_index_q2 <= mapped_index_s1;
            any_irq_active_q2 <= any_irq_active_q1; // Pass through
        end
    end

    // --- Pipeline Stage 2a: Shift Calculation ---
    // Combinational logic for Stage 2a
    logic [31:0] shifted_index_s2a;

    // Combinational calculation: Shift the mapped index
    assign shifted_index_s2a = mapped_index_q2 << 4;

    // Register outputs of Stage 2a for Stage 2b
    always @(posedge clk or posedge reset) begin
        if (reset || map_update) begin // Flush pipeline
            shifted_index_q2a <= 32'b0;
            any_irq_active_q2a <= 1'b0; // Pass through the 'any active' state
        end else begin
            shifted_index_q2a <= shifted_index_s2a;
            any_irq_active_q2a <= any_irq_active_q2; // Pass through
        end
    end

    // --- Pipeline Stage 2b: Vector Addition & Output Generation ---
    // Combinational logic for Stage 2b
    logic [31:0] irq_vector_s2b;
    logic irq_req_s2b;

    // Combinational vector calculation using the registered shifted index from Stage 2a
    assign irq_vector_s2b = vector_base + shifted_index_q2a;
    // Assert request if any IRQ was active (state propagated through pipeline)
    assign irq_req_s2b = any_irq_active_q2a;

    // Output Registers: Hold the final vector and request signal
    always @(posedge clk or posedge reset) begin
        if (reset || map_update) begin // Flush pipeline / Clear outputs
            irq_vector <= 32'b0;
            irq_req <= 1'b0;
        end else begin
            irq_vector <= irq_vector_s2b;
            irq_req <= irq_req_s2b;
        end
    end

endmodule