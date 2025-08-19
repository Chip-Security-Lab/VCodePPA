//SystemVerilog
// Top level module
module reset_stretcher #(
  parameter STRETCH_CYCLES = 16
) (
  input  wire clk,
  input  wire reset_in,
  output wire reset_out
);
  
  localparam COUNTER_WIDTH = $clog2(STRETCH_CYCLES);
  wire [COUNTER_WIDTH:0] counter_value;
  wire counter_nonzero;
  
  // Instantiate counter module
  stretch_counter #(
    .STRETCH_CYCLES(STRETCH_CYCLES)
  ) counter_inst (
    .clk           (clk),
    .reset_in      (reset_in),
    .counter_value (counter_value),
    .counter_nonzero(counter_nonzero)
  );
  
  // Instantiate reset logic module
  reset_logic reset_logic_inst (
    .clk            (clk),
    .reset_in       (reset_in),
    .counter_nonzero(counter_nonzero),
    .reset_out      (reset_out)
  );
  
endmodule

// Counter module for stretch timing
module stretch_counter #(
  parameter STRETCH_CYCLES = 16
) (
  input  wire clk,
  input  wire reset_in,
  output reg [$clog2(STRETCH_CYCLES):0] counter_value,
  output wire counter_nonzero
);
  
  localparam COUNTER_WIDTH = $clog2(STRETCH_CYCLES);
  
  // Counter logic with optimized implementation
  always @(posedge clk) begin
    if (reset_in)
      counter_value <= STRETCH_CYCLES;
    else if (|counter_value) // Bit-wise OR is faster than comparison
      counter_value <= counter_value - 1'b1;
  end
  
  // Optimized counter status signal using bit-wise OR
  assign counter_nonzero = |counter_value;
  
endmodule

// Reset output logic module
module reset_logic (
  input  wire clk,
  input  wire reset_in,
  input  wire counter_nonzero,
  output reg  reset_out
);
  
  // Reset output generation logic with registered output
  always @(posedge clk) begin
    reset_out <= reset_in | counter_nonzero;
  end
  
endmodule