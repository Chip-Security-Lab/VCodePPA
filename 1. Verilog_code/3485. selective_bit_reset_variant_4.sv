//SystemVerilog
module selective_bit_reset(
  input clk, rst_n,
  input reset_bit0, reset_bit1, reset_bit2,
  input [2:0] data_in,
  output reg [2:0] data_out
);
  // Buffer registers for high fan-out signals
  reg [2:0] data_in_buf1, data_in_buf2;
  reg reset_bit0_buf1, reset_bit0_buf2;
  reg reset_bit1_buf1, reset_bit1_buf2;
  reg reset_bit2_buf1, reset_bit2_buf2;
  
  // Combined always block for all sequential logic (buffering and main logic)
  always @(posedge clk) begin
    if (!rst_n) begin
      // First stage buffer reset
      data_in_buf1 <= 3'b000;
      reset_bit0_buf1 <= 1'b0;
      reset_bit1_buf1 <= 1'b0;
      reset_bit2_buf1 <= 1'b0;
      
      // Second stage buffer reset
      data_in_buf2 <= 3'b000;
      reset_bit0_buf2 <= 1'b0;
      reset_bit1_buf2 <= 1'b0;
      reset_bit2_buf2 <= 1'b0;
      
      // Output reset
      data_out <= 3'b000;
    end
    else begin
      // First stage buffering
      data_in_buf1 <= data_in;
      reset_bit0_buf1 <= reset_bit0;
      reset_bit1_buf1 <= reset_bit1;
      reset_bit2_buf1 <= reset_bit2;
      
      // Second stage buffering
      data_in_buf2 <= data_in_buf1;
      reset_bit0_buf2 <= reset_bit0_buf1;
      reset_bit1_buf2 <= reset_bit1_buf1;
      reset_bit2_buf2 <= reset_bit2_buf1;
      
      // Main logic - selective bit reset
      data_out[0] <= reset_bit0_buf2 ? 1'b0 : data_in_buf2[0];
      data_out[1] <= reset_bit1_buf2 ? 1'b0 : data_in_buf2[1];
      data_out[2] <= reset_bit2_buf2 ? 1'b0 : data_in_buf2[2];
    end
  end
endmodule