//SystemVerilog
module parity_with_error_latch_pipeline(
  input clk, rst, clear_error,
  input [7:0] data,
  input parity_in,
  output reg error_latched
);

  // Stage 1: Calculate even parity
  wire even_parity_stage1;
  wire [7:0] data_stage1;

  assign data_stage1 = data;
  assign even_parity_stage1 = data_stage1[0] ^ data_stage1[1] ^ data_stage1[2] ^ data_stage1[3] ^ 
                              data_stage1[4] ^ data_stage1[5] ^ data_stage1[6] ^ data_stage1[7];

  // Stage 2: Calculate current error
  wire current_error_stage2;
  wire even_parity_stage2;

  assign even_parity_stage2 = even_parity_stage1;
  assign current_error_stage2 = even_parity_stage2 ^ parity_in;

  // Stage 3: Determine next error state
  reg next_error_state_stage3;
  wire current_error_stage3;

  assign current_error_stage3 = current_error_stage2;

  always @(*) begin
    if (rst || clear_error)
      next_error_state_stage3 = 1'b0;
    else if (current_error_stage3)
      next_error_state_stage3 = 1'b1;
    else
      next_error_state_stage3 = error_latched;
  end

  // Stage 4: Update error latch
  always @(posedge clk) begin
    error_latched <= next_error_state_stage3;
  end

endmodule