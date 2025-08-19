//SystemVerilog
module IVMU_MaskedPriority #(parameter W=16) (
    input clk, rst_n,
    input [W-1:0] int_req_in, // Input interrupt requests
    input [W-1:0] mask_in,   // Input mask
    input valid_in,          // Input valid signal
    output [$clog2(W)-1:0] vec_idx, // Output vector index
    output valid_out         // Output valid signal
);

localparam N = $clog2(W);

// Stage 1: Calculate active_req and conditions
wire [W-1:0] active_req_s1;
wire cond_idx_0_s1;
wire cond_idx_1_s1;
wire cond_keep_old_s1;

// Registers for Stage 1 outputs (conditions and valid)
reg cond_idx_0_s1_reg;
reg cond_idx_1_s1_reg;
reg cond_keep_old_s1_reg;
reg valid_s1_reg;

// Combinational logic for Stage 1
assign active_req_s1 = int_req_in & ~mask_in;
assign cond_idx_0_s1 = active_req_s1[0];
assign cond_idx_1_s1 = ~active_req_s1[0] & active_req_s1[1];
assign cond_keep_old_s1 = ~active_req_s1[0] & ~active_req_s1[1];

// Registering Stage 1 outputs
always @(posedge clk) begin
    if (!rst_n) begin
        cond_idx_0_s1_reg <= 1'b0;
        cond_idx_1_s1_reg <= 1'b0;
        cond_keep_old_s1_reg <= 1'b0;
        valid_s1_reg <= 1'b0;
    end else begin
        cond_idx_0_s1_reg <= cond_idx_0_s1;
        cond_idx_1_s1_reg <= cond_idx_1_s1;
        cond_keep_old_s1_reg <= cond_keep_old_s1;
        valid_s1_reg <= valid_in; // Pass valid through
    end
end

// Stage 2: Calculate vec_idx_comb and register final vec_idx
wire [N-1:0] vec_idx_comb_s2;
reg [N-1:0] vec_idx_reg; // This is the final output register (state)
reg valid_s2_reg; // Valid signal for Stage 2 output

// Combinational logic for Stage 2
// This logic depends on the registered conditions from Stage 1 AND the current vec_idx_reg
genvar i;
generate
  for (i = 0; i < N; i = i + 1) begin : gen_idx_bits_s2
    if (i == 0) begin : bit_0_s2
      assign vec_idx_comb_s2[i] = cond_idx_1_s1_reg | (cond_keep_old_s1_reg & vec_idx_reg[i]);
    end else begin : other_bits_s2
      assign vec_idx_comb_s2[i] = cond_keep_old_s1_reg & vec_idx_reg[i];
    end
  end
endgenerate

// Registering Stage 2 output (the final vec_idx)
always @(posedge clk) begin
    if (!rst_n) begin
        vec_idx_reg <= {N{1'b0}}; // Reset to 0
        valid_s2_reg <= 1'b0;
    end else begin
        // vec_idx_reg is a state register. It updates based on valid data from the pipeline.
        // If valid data arrives from Stage 1 (valid_s1_reg is high), update vec_idx_reg.
        // Otherwise, it holds its value.
        if (valid_s1_reg) begin
            vec_idx_reg <= vec_idx_comb_s2;
        end
        // valid_s2_reg becomes high one cycle after valid_s1_reg is high.
        valid_s2_reg <= valid_s1_reg;
    end
end

// Output assignments
assign vec_idx = vec_idx_reg;
assign valid_out = valid_s2_reg;

endmodule