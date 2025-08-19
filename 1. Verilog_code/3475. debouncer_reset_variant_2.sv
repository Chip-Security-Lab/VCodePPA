//SystemVerilog
`timescale 1ns / 1ps
module debouncer_reset #(parameter DELAY = 16)(
  input clk, rst, button_in,
  output reg button_out
);
  reg [DELAY-1:0] shift_reg;
  reg button_in_buf; // Buffer for button_in
  reg rst_buf1, rst_buf2; // Buffers for reset signal
  reg all_ones, all_zeros; // Buffered condition signals
  
  // Input buffering to reduce fan-out on input signals
  always @(posedge clk) begin
    button_in_buf <= button_in;
    rst_buf1 <= rst;
    rst_buf2 <= rst_buf1;
  end
  
  // Shift register logic
  always @(posedge clk) begin
    if (rst_buf2) begin
      shift_reg <= {DELAY{1'b0}};
    end else begin
      shift_reg <= {shift_reg[DELAY-2:0], button_in_buf};
    end
  end
  
  // Pre-compute detection conditions to reduce combinational path
  always @(posedge clk) begin
    all_ones <= &shift_reg;
    all_zeros <= ~|shift_reg;
  end
  
  // Output logic with buffered conditions
  always @(posedge clk) begin
    if (rst_buf2) begin
      button_out <= 1'b0;
    end else begin
      if (all_ones)
        button_out <= 1'b1;
      else if (all_zeros)
        button_out <= 1'b0;
    end
  end
endmodule