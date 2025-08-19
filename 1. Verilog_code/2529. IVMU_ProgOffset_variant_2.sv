//SystemVerilog
module IVMU_ProgOffset #(parameter OFFSET_W=16) (
    input clk,
    input [OFFSET_W-1:0] base_addr,
    input [3:0] int_id,
    output reg [OFFSET_W-1:0] vec_addr
);

// Calculate the offset value: (int_id << 2)
// int_id is 4 bits. Shifting left by 2 results in a value up to 6 bits.
// Need to zero-extend this value to OFFSET_W bits for addition.
// Assumes OFFSET_W >= 6. If OFFSET_W < 6, the shift would truncate.
// Default OFFSET_W=16, so this is safe.
wire [OFFSET_W-1:0] offset_value;
assign offset_value = {{(OFFSET_W > 6 ? OFFSET_W - 6 : 0){1'b0}}, int_id[3:0], 2'b0};

// Implement the addition using the conditional inversion structure
// This structure is typically used for A + B or A - B (A + ~B + 1)
// For addition (A + B), the subtract mode signal is 0.
wire sub_mode = 1'b0; // Hardwired for addition

// Operand B is conditionally inverted based on sub_mode
// For addition (sub_mode=0), this is offset_value ^ 0 = offset_value
wire [OFFSET_W-1:0] operand_b_inverted_conditionally;
assign operand_b_inverted_conditionally = offset_value ^ {OFFSET_W{sub_mode}};

// The carry-in is 1 for subtraction (A + ~B + 1) and 0 for addition (A + B + 0)
// For addition (sub_mode=0), this is 0
wire cin = sub_mode;

// The sum is calculated as base_addr + (offset_value XOR sub_mode) + sub_mode
// This is base_addr + operand_b_inverted_conditionally + cin
wire [OFFSET_W-1:0] sum_intermediate;
assign sum_intermediate = base_addr + operand_b_inverted_conditionally + cin;

// Register the result
always @(posedge clk) begin
    vec_addr <= sum_intermediate;
end

endmodule