//SystemVerilog
module IVMU_ProgOffset_pipelined #(parameter OFFSET_W=16) (
    input clk,
    input rst_n, // Added reset input
    input [OFFSET_W-1:0] base_addr_in,
    input [3:0] int_id_in,
    output [OFFSET_W-1:0] vec_addr
);

// Signals for pipeline stage 1 (input registration and shift computation)
reg [OFFSET_W-1:0] base_addr_s1;
reg [OFFSET_W-1:0] shifted_int_id_s1; // Result of int_id_in << 2, registered

// Stage 1: Register inputs and perform shift
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        base_addr_s1 <= 0;
        shifted_int_id_s1 <= 0;
    end else begin
        base_addr_s1 <= base_addr_in;
        // Perform the shift operation (int_id_in << 2) and extend to OFFSET_W
        // Optimized shift: Rely on assignment semantics for zero-extension/truncation
        shifted_int_id_s1 <= (int_id_in << 2);
    end
end

// Signals for pipeline stage 2 (addition computation and output registration)
reg [OFFSET_W-1:0] vec_addr_s2; // Final output, registered

// Stage 2: Perform addition and register the final result
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        vec_addr_s2 <= 0;
    end else begin
        vec_addr_s2 <= base_addr_s1 + shifted_int_id_s1;
    end
end

// Assign the final registered output
assign vec_addr = vec_addr_s2;

endmodule