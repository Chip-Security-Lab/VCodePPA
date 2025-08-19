//SystemVerilog
// Top-level module for even parity generation with pipelined architecture
module even_parity_gen(
  input clk,
  input rst_n,
  input [7:0] data_in,
  output reg parity_out
);

  // Pipeline stage registers
  reg [7:0] data_stage1;
  reg parity_stage1;
  
  // Data path control signals
  wire parity_result;
  
  // Pipeline stage 1: Data input registration
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_stage1 <= 8'h0;
    end else begin
      data_stage1 <= data_in;
    end
  end

  // Pipeline stage 2: Parity calculation
  parity_calculator u_parity_calculator (
    .data(data_stage1),
    .parity(parity_result)
  );

  // Pipeline stage 3: Output registration
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      parity_out <= 1'b0;
    end else begin
      parity_out <= parity_result;
    end
  end

endmodule

// Optimized parity calculator with reduced logic depth
module parity_calculator(
  input [7:0] data,
  output parity
);
  
  // Split XOR tree for better timing
  wire [3:0] xor_l1;
  wire [1:0] xor_l2;
  
  // Level 1 XOR
  assign xor_l1[0] = data[0] ^ data[1];
  assign xor_l1[1] = data[2] ^ data[3];
  assign xor_l1[2] = data[4] ^ data[5];
  assign xor_l1[3] = data[6] ^ data[7];
  
  // Level 2 XOR
  assign xor_l2[0] = xor_l1[0] ^ xor_l1[1];
  assign xor_l2[1] = xor_l1[2] ^ xor_l1[3];
  
  // Final XOR
  assign parity = xor_l2[0] ^ xor_l2[1];

endmodule