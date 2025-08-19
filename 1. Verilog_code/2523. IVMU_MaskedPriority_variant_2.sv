//SystemVerilog
module IVMU_MaskedPriority_Pipelined #(parameter W=16) (
    input clk,
    input rst_n,
    input flush, // Synchronous flush input
    input [W-1:0] int_req,
    input [W-1:0] mask,
    input i_valid, // Input valid signal
    output [$clog2(W)-1:0] vec_idx,
    output o_valid // Output valid signal
);

// Assume W >= 2 based on original code accessing index 1.
// Output width is [$clog2(W)-1:0]
localparam VEC_IDX_WIDTH = $clog2(W);

// Stage 1: Calculate active requests (Combinational)
// Use localparams for safety, though W>=2 assumed.
localparam HAS_BIT_0 = (W > 0);
localparam HAS_BIT_1 = (W > 1);

wire active_req_0_s1_comb = HAS_BIT_0 ? (int_req[0] & ~mask[0]) : 1'b0;
wire active_req_1_s1_comb = HAS_BIT_1 ? (int_req[1] & ~mask[1]) : 1'b0;

// Pipeline registers for Stage 1 outputs
reg active_req_0_s1;
reg active_req_1_s1;
reg valid_s1; // Valid signal for data entering Stage 2

always @(posedge clk) begin
    if (!rst_n) begin
        active_req_0_s1 <= 1'b0;
        active_req_1_s1 <= 1'b0;
        valid_s1 <= 1'b0;
    end else if (flush) begin // Synchronous flush
        active_req_0_s1 <= 1'b0;
        active_req_1_s1 <= 1'b0;
        valid_s1 <= 1'b0;
    end else begin
        active_req_0_s1 <= active_req_0_s1_comb;
        active_req_1_s1 <= active_req_1_s1_comb;
        valid_s1 <= i_valid; // Propagate input valid
    end
end

// Stage 2 (Output Stage): Determine vec_idx and update condition, then register
// This stage uses the registered outputs from Stage 1 (active_req_0_s1, active_req_1_s1, valid_s1)
reg [VEC_IDX_WIDTH-1:0] vec_idx_reg; // Final output register
reg o_valid_reg; // Output valid register

always @(posedge clk) begin
    if (!rst_n) begin
        vec_idx_reg <= {VEC_IDX_WIDTH{1'b0}}; // Reset value 0
        o_valid_reg <= 1'b0;
    end else if (flush) begin // Synchronous flush
        // On flush, the output should become invalid.
        // vec_idx_reg can either hold or reset to a default (like 0).
        // Resetting to 0 seems safer and matches initial state.
        vec_idx_reg <= {VEC_IDX_WIDTH{1'b0}};
        o_valid_reg <= 1'b0;
    end else begin
        // If valid data arrived from Stage 1 (now available as valid_s1)...
        if (valid_s1) begin
            // ... determine if the output register should update based on this data packet.
            if (active_req_0_s1) begin
                vec_idx_reg <= {VEC_IDX_WIDTH{1'b0}}; // Value 0
            end else if (active_req_1_s1) begin
                vec_idx_reg <= {VEC_IDX_WIDTH{1'b0}} + 1'b1; // Value 1
            end
            // If neither active_req_0_s1 nor active_req_1_s1 is true, vec_idx_reg holds its value.
            // The output is valid as a new decision (even if it's 'hold') is made based on valid input data.
            o_valid_reg <= 1'b1;
        end else begin
             // If no valid data arrived from Stage 1, the output is not valid.
             // vec_idx_reg holds its value implicitly.
             o_valid_reg <= 1'b0;
        end
    end
end

// Assign final outputs
assign vec_idx = vec_idx_reg;
assign o_valid = o_valid_reg;

endmodule