//SystemVerilog
// SystemVerilog
// Top module: IVMU_ProgOffset - Pipelined version
module IVMU_ProgOffset #(
    parameter OFFSET_W = 16 // Address width
) (
    input clk,
    input rst_n, // Active low reset added for pipeline
    input [OFFSET_W-1:0] base_addr,
    input [3:0] int_id,
    input input_valid, // Indicates valid input data
    output [OFFSET_W-1:0] vec_addr,
    output output_valid // Indicates valid output data
);

    // --- Pipeline Registers and Wires ---

    // Stage 1: Scaler Logic (Combinatorial)
    // Calculates scaled_int_value and passes base_addr and valid
    wire [OFFSET_W-1:0] scaled_int_value_s1_comb;
    wire [OFFSET_W-1:0] base_addr_s1_comb; // Pass-through
    wire valid_s1_comb; // Pass-through input_valid

    // Stage 1 Registers (Output of Stage 1)
    // Store results from Stage 1 for Stage 2
    reg [OFFSET_W-1:0] base_addr_s2_reg;
    reg [OFFSET_W-1:0] scaled_int_value_s2_reg;
    reg valid_s2_reg;

    // Stage 2: Combiner Logic (Combinatorial)
    // Calculates sum using registered values from Stage 1
    wire [OFFSET_W-1:0] sum_s2_comb;
    wire valid_s2_comb; // Pass-through valid_s2_reg

    // Stage 2 Registers (Output of Stage 2)
    // Store results from Stage 2 for Output Stage
    reg [OFFSET_W-1:0] sum_s3_reg;
    reg valid_s3_reg;

    // Stage 3: Output Registers
    // Final registered outputs
    reg [OFFSET_W-1:0] vec_addr_reg;
    reg output_valid_reg;

    // Assign final outputs from output registers
    assign vec_addr = vec_addr_reg;
    assign output_valid = output_valid_reg;


    // --- Stage 1: Scaler Logic ---
    // Input: base_addr, int_id, input_valid
    // Output: scaled_int_value_s1_comb, base_addr_s1_comb, valid_s1_comb
    // This is the combinatorial part of the first pipeline stage
    assign base_addr_s1_comb = base_addr; // base_addr is needed in the next stage
    assign valid_s1_comb = input_valid;   // valid signal propagates
    // Scale int_id by 4 (left shift by 2) and zero-extend to OFFSET_W
    assign scaled_int_value_s1_comb = ({{OFFSET_W-4{1'b0}}, int_id}) << 2;


    // --- Stage 1 Registers ---
    // Register outputs of Stage 1 (combinatorial logic)
    // These registers feed Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            base_addr_s2_reg <= {OFFSET_W{1'b0}};
        end else begin
            base_addr_s2_reg <= base_addr_s1_comb;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scaled_int_value_s2_reg <= {OFFSET_W{1'b0}};
        end else begin
            scaled_int_value_s2_reg <= scaled_int_value_s1_comb;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_s2_reg <= 1'b0;
        end else begin
            valid_s2_reg <= valid_s1_comb; // Propagate valid
        end
    end


    // --- Stage 2: Combiner Logic ---
    // Input: base_addr_s2_reg, scaled_int_value_s2_reg, valid_s2_reg (from Stage 1 registers)
    // Output: sum_s2_comb, valid_s2_comb
    // This is the combinatorial part of the second pipeline stage
    assign valid_s2_comb = valid_s2_reg; // Propagate valid from previous stage registers
    // Perform addition using registered values from Stage 1
    assign sum_s2_comb = base_addr_s2_reg + scaled_int_value_s2_reg;


    // --- Stage 2 Registers ---
    // Register outputs of Stage 2 (combinatorial logic)
    // These registers feed the Output Stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_s3_reg <= {OFFSET_W{1'b0}};
        end else begin
            sum_s3_reg <= sum_s2_comb;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_s3_reg <= 1'b0;
        end else begin
            valid_s3_reg <= valid_s2_comb; // Propagate valid
        end
    end


    // --- Stage 3: Output Registers ---
    // Register final result and valid signal
    // These registers provide the module outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vec_addr_reg <= {OFFSET_W{1'b0}};
        end else begin
            vec_addr_reg <= sum_s3_reg;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_valid_reg <= 1'b0;
        end else begin
            output_valid_reg <= valid_s3_reg; // Final output valid
        end
    end

endmodule