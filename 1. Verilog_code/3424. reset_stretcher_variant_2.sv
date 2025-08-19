//SystemVerilog
module reset_stretcher #(
  parameter STRETCH_CYCLES = 16
) (
  input  wire clk,
  input  wire reset_in,
  output wire reset_out
);
  // Define counter width based on parameter
  localparam COUNTER_WIDTH = $clog2(STRETCH_CYCLES) + 1;
  
  // Pipeline stage 1: Input registration
  reg reset_in_reg;
  always @(posedge clk) begin
    reset_in_reg <= reset_in;
  end
  
  // Pipeline stage 2: Counter logic
  reg [COUNTER_WIDTH-1:0] stretch_counter;
  reg counter_active;
  
  always @(posedge clk) begin
    if (reset_in_reg) begin
      // Reset detected - load counter with full stretch value
      stretch_counter <= STRETCH_CYCLES;
      counter_active <= 1'b1;
    end
    else if (stretch_counter > 0) begin
      // Counter still active - decrement
      stretch_counter <= stretch_counter - 1'b1;
      counter_active <= (stretch_counter > 1);
    end
    else begin
      // Counter inactive - maintain state
      stretch_counter <= 0;
      counter_active <= 1'b0;
    end
  end
  
  // Pipeline stage 3: Output generation
  reg reset_out_reg;
  always @(posedge clk) begin
    reset_out_reg <= counter_active | reset_in_reg;
  end
  
  // Output assignment
  assign reset_out = reset_out_reg;
  
endmodule