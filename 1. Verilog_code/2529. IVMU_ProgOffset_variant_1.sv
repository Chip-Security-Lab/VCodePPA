//SystemVerilog
module IVMU_ProgOffset_pipelined #(parameter OFFSET_W=16) (
    input logic clk,
    input logic reset_n, // Active low reset
    input logic valid_in,
    input logic [OFFSET_W-1:0] base_addr,
    input logic [3:0] int_id,
    output logic valid_out,
    output logic [OFFSET_W-1:0] vec_addr
);

// Stage 0: Input Registers
// Registers input data and valid signal
logic valid_s0;
logic [OFFSET_W-1:0] base_addr_s0;
logic [3:0] int_id_s0;

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        valid_s0 <= 1'b0;
        base_addr_s0 <= '0;
        int_id_s0 <= '0;
    end else begin
        valid_s0 <= valid_in;
        base_addr_s0 <= base_addr;
        int_id_s0 <= int_id;
    end
end

// Stage 1: Shift Operation & Registers
// Performs the shift and registers the result and other necessary data
logic [OFFSET_W-1:0] shifted_int_id_s1_comb;
assign shifted_int_id_s1_comb = int_id_s0 << 2;

logic valid_s1;
logic [OFFSET_W-1:0] base_addr_s1;
logic [OFFSET_W-1:0] shifted_int_id_s1; // Result of shift from stage 1

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        valid_s1 <= 1'b0;
        base_addr_s1 <= '0;
        shifted_int_id_s1 <= '0;
    end else begin
        valid_s1 <= valid_s0;
        base_addr_s1 <= base_addr_s0;
        shifted_int_id_s1 <= shifted_int_id_s1_comb;
    end
end

// Stage 2: Addition Operation & Output Registers
// Performs the addition and registers the final result and valid signal
logic [OFFSET_W-1:0] vec_addr_s2_comb;
assign vec_addr_s2_comb = base_addr_s1 + shifted_int_id_s1;

logic valid_s2;

always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        valid_s2 <= 1'b0;
        vec_addr <= '0;
    end else begin
        valid_s2 <= valid_s1;
        vec_addr <= vec_addr_s2_comb;
    end
end

// Assign final valid output
assign valid_out = valid_s2;

endmodule