//SystemVerilog
module lfsr_parity_gen(
  input wire clk,
  input wire rst,
  input wire [7:0] data_in,
  output wire parity
);
  // LFSR state registers
  reg [3:0] lfsr_state_q;
  wire [3:0] lfsr_next;
  
  // Pipeline registers for data processing
  reg [7:0] data_in_q;
  reg data_parity_q;
  reg lfsr_bit_q;
  reg parity_result_q;
  
  // LFSR next state logic
  assign lfsr_next = {lfsr_state_q[2:0], lfsr_state_q[3] ^ lfsr_state_q[2]};
  
  // First pipeline stage: input capture and LFSR update
  always @(posedge clk) begin
    if (rst) begin
      lfsr_state_q <= 4'b1111;
      data_in_q <= 8'h00;
    end else begin
      lfsr_state_q <= lfsr_next;
      data_in_q <= data_in;
    end
  end
  
  // Second pipeline stage: compute individual parities
  always @(posedge clk) begin
    if (rst) begin
      data_parity_q <= 1'b0;
      lfsr_bit_q <= 1'b0;
    end else begin
      data_parity_q <= ^data_in_q;
      lfsr_bit_q <= lfsr_state_q[0];
    end
  end
  
  // Final pipeline stage: combine parities
  always @(posedge clk) begin
    if (rst) begin
      parity_result_q <= 1'b0;
    end else begin
      parity_result_q <= data_parity_q ^ lfsr_bit_q;
    end
  end
  
  // Output assignment
  assign parity = parity_result_q;
  
endmodule