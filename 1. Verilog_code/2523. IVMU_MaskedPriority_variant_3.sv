//SystemVerilog
module IVMU_MaskedPriority_Pipelined #(parameter W=16) (
    input clk, rst_n,
    input [W-1:0] int_req,
    input [W-1:0] mask,
    output reg [$clog2(W)-1:0] vec_idx
);

localparam V = $clog2(W); // Width of vec_idx

// Stage 0: Input processing (Combinational)
wire [W-1:0] active_req;
wire a0, a1;

assign active_req = int_req & ~mask;
assign a0 = active_req[0];
// Access active_req[1] only if W > 1, otherwise treat as 0
assign a1 = (W > 1) ? active_req[1] : 1'b0;

// Stage 1: Pipeline Registers (Capture Stage 0 outputs and feedback)
reg a0_s1_reg;
reg a1_s1_reg;
reg [V-1:0] vec_idx_s1_reg; // Registered feedback from previous cycle's output

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a0_s1_reg <= 1'b0;
        a1_s1_reg <= 1'b0;
        vec_idx_s1_reg <= {V{1'b0}};
    end else begin
        a0_s1_reg <= a0;
        a1_s1_reg <= a1;
        vec_idx_s1_reg <= vec_idx; // Capture the state from the end of the previous cycle (Stage 3 output)
    end
end

// Stage 2: Buffer Registers (Buffer high-fanout signals from Stage 1 registers)
reg a0_s2_buf;
reg a1_s2_buf;
reg [V-1:0] vec_idx_s2_buf;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a0_s2_buf <= 1'b0;
        a1_s2_buf <= 1'b0;
        vec_idx_s2_buf <= {V{1'b0}};
    end else begin
        a0_s2_buf <= a0_s1_reg;
        a1_s2_buf <= a1_s1_reg;
        vec_idx_s2_buf <= vec_idx_s1_reg;
    end
end

// Stage 2: Combinational logic for next state calculation (Uses buffered signals)
// This calculates the 'next_vec_idx' value based on the registered inputs and state from Stage 2 buffers
wire [V-1:0] next_vec_idx_s2_comb; // Output of Stage 2 combinational logic

generate
    if (V > 0) begin : gen_next_vec_idx_s2_comb_bits
        // LSB (Bit 0) logic: (~a0_s2_buf & (a1_s2_buf | vec_idx_s2_buf[0]))
        assign next_vec_idx_s2_comb[0] = (~a0_s2_buf & (a1_s2_buf | vec_idx_s2_buf[0]));

        // Bit 1 logic: (~a0_s2_buf & ~a1_s2_buf & vec_idx_s2_buf[1])
        if (V >= 2) begin : gen_bit1_s2
            assign next_vec_idx_s2_comb[1] = (~a0_s2_buf & ~a1_s2_buf & vec_idx_s2_buf[1]);
        end

        // Higher bits (Bit 2 to V-1) logic: (~a0_s2_buf & ~a1_s2_buf & vec_idx_s2_buf[i])
        if (V >= 3) begin : gen_higher_bits_s2
            genvar i;
            for (i = 2; i < V; i = i + 1) begin : bit_logic_s2
                assign next_vec_idx_s2_comb[i] = (~a0_s2_buf & ~a1_s2_buf & vec_idx_s2_buf[i]);
            end
        end

    end else begin // V=0, W=1 (vec_idx is 0-width)
        assign next_vec_idx_s2_comb = {V{1'b0}}; // Assign 0-width value
    end
endgenerate


// Stage 3: Pipeline Register (Final Output)
// The output register 'vec_idx' holds the state, registered from the Stage 2 calculation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vec_idx <= {V{1'b0}};
    end else begin
        vec_idx <= next_vec_idx_s2_comb; // Register the calculated next state
    end
end

endmodule