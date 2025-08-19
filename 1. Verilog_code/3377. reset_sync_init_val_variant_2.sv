//SystemVerilog
//
// Reset Synchronization System - IEEE 1364-2005 Verilog
// 
// Top-level module for reset synchronization with configurable initial value
//

module reset_sync_init_val #(
  parameter INIT_VAL = 1'b0
)(
  input  wire clk,    // System clock
  input  wire rst_n,  // Asynchronous reset (active low)
  output wire rst_sync // Synchronized reset output
);

  wire flop_out;
  
  // First stage flip-flop for metastability management
  reset_ff_stage #(
    .INIT_VAL(INIT_VAL)
  ) first_stage (
    .clk       (clk),
    .rst_n     (rst_n),
    .data_in   (~INIT_VAL),
    .data_out  (flop_out)
  );
  
  // Output stage flip-flop for glitch-free reset
  reset_ff_stage #(
    .INIT_VAL(INIT_VAL)
  ) output_stage (
    .clk       (clk),
    .rst_n     (rst_n),
    .data_in   (flop_out),
    .data_out  (rst_sync)
  );

endmodule

//
// Single flip-flop stage with configurable reset value
//
module reset_ff_stage #(
  parameter INIT_VAL = 1'b0
)(
  input  wire clk,      // System clock
  input  wire rst_n,    // Asynchronous reset (active low)
  input  wire data_in,  // Input data
  output reg  data_out  // Output data
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      data_out <= INIT_VAL;
    else
      data_out <= data_in;
  end

endmodule