//SystemVerilog
module cla_adder_8bit (
    input clk,
    input rst_n,
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum
);

// Internal signals for CLA logic
wire [7:0] generate_bit; // g[i] = a[i] & b[i]
wire [7:0] propagate_bit; // p[i] = a[i] ^ b[i]
wire [7:0] carry_into_bit; // c[i] = carry into bit i
wire [1:0] block_generate; // G[j] for block j (4-bit blocks)
wire [1:0] block_propagate; // P[j] for block j (4-bit blocks)
wire [7:0] sum_combinational; // s[i] = p[i] ^ c[i]

// Registered output
reg [7:0] sum_registered;

// Define the input carry (assuming 0 for simple addition)
parameter CARRY_IN = 1'b0; // Input carry into bit 0

// Calculate generate and propagate signals for each bit
generate
  genvar i;
  for (i = 0; i < 8; i = i + 1) begin : gen_prop_bits
    assign generate_bit[i] = a[i] & b[i];
    assign propagate_bit[i] = a[i] ^ b[i];
  end
endgenerate

// Calculate block generate and propagate signals (4-bit blocks)
// Block 0 (bits 0-3)
assign block_generate[0] = generate_bit[3] | (propagate_bit[3] & generate_bit[2]) | (propagate_bit[3] & propagate_bit[2] & generate_bit[1]) | (propagate_bit[3] & propagate_bit[2] & propagate_bit[1] & generate_bit[0]);
assign block_propagate[0] = propagate_bit[3] & propagate_bit[2] & propagate_bit[1] & propagate_bit[0];

// Block 1 (bits 4-7)
assign block_generate[1] = generate_bit[7] | (propagate_bit[7] & generate_bit[6]) | (propagate_bit[7] & propagate_bit[6] & generate_bit[5]) | (propagate_bit[7] & propagate_bit[6] & propagate_bit[5] & generate_bit[4]);
assign block_propagate[1] = propagate_bit[7] & propagate_bit[6] & propagate_bit[5] & propagate_bit[4];

// Calculate carries using CLA structure
// carry_into_bit[0] is the input carry
assign carry_into_bit[0] = CARRY_IN;

// Calculate internal carries within Block 0 (bits 0-3) - ripple within block
assign carry_into_bit[1] = generate_bit[0] | (propagate_bit[0] & carry_into_bit[0]);
assign carry_into_bit[2] = generate_bit[1] | (propagate_bit[1] & carry_into_bit[1]);
assign carry_into_bit[3] = generate_bit[2] | (propagate_bit[2] & carry_into_bit[2]);

// Calculate carry into Block 1 (bit 4) - uses block lookahead
assign carry_into_bit[4] = block_generate[0] | (block_propagate[0] & carry_into_bit[0]); // carry_into_bit[0] is carry into block 0

// Calculate internal carries within Block 1 (bits 4-7) - ripple within block
assign carry_into_bit[5] = generate_bit[4] | (propagate_bit[4] & carry_into_bit[4]);
assign carry_into_bit[6] = generate_bit[5] | (propagate_bit[5] & carry_into_bit[5]);
assign carry_into_bit[7] = generate_bit[6] | (propagate_bit[6] & carry_into_bit[6]);

// Calculate the sum bits
generate
  for (i = 0; i < 8; i = i + 1) begin : sum_bits
    assign sum_combinational[i] = propagate_bit[i] ^ carry_into_bit[i];
  end
endgenerate

// Register the combinational sum output
always @(posedge clk or negedge rst_n) begin
  if (~rst_n) begin
    sum_registered <= 8'b0;
  end else begin
    sum_registered <= sum_combinational;
  end
end

// Assign the registered output to the module output
assign sum = sum_registered;

endmodule