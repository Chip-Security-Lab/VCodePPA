//SystemVerilog
module serial_parity_calc(
  input clk, rst, bit_in, start,
  output reg parity_done,
  output reg parity_bit
);
  reg [3:0] bit_count;
  wire count_complete;
  wire reset_condition;
  
  assign reset_condition = rst || start;
  assign count_complete = (bit_count == 4'd7);
  
  // Bit counter control - manages the bit counting process
  always @(posedge clk) begin
    if (reset_condition) begin
      bit_count <= 4'd0;
    end else if (bit_count < 4'd8) begin
      bit_count <= bit_count + 1'b1;
    end
  end
  
  // Parity calculation - handles XOR operation on incoming bits
  always @(posedge clk) begin
    if (reset_condition) begin
      parity_bit <= 1'b0;
    end else if (bit_count < 4'd8) begin
      parity_bit <= parity_bit ^ bit_in;
    end
  end
  
  // Completion detection - generates the done signal
  always @(posedge clk) begin
    if (reset_condition) begin
      parity_done <= 1'b0;
    end else begin
      parity_done <= count_complete;
    end
  end
endmodule