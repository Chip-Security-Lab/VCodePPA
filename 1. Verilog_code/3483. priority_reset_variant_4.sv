//SystemVerilog
module priority_reset(
  input clk, global_rst, subsystem_rst, local_rst,
  input [7:0] data_in,
  output reg [7:0] data_out
);
  // Pre-compute reset conditions in separate pipeline stage
  reg [2:0] reset_signals_r;
  reg [7:0] data_in_r;
  
  // First pipeline stage - register inputs
  always @(posedge clk) begin
    reset_signals_r <= {global_rst, subsystem_rst, local_rst};
    data_in_r <= data_in;
  end
  
  // Second pipeline stage - compute output
  reg [1:0] reset_type;
  reg [7:0] next_data;
  
  always @(*) begin
    // Determine reset type with balanced conditional structure
    reset_type = {1'b0, 1'b0};
    if (reset_signals_r[2])       // global_rst
      reset_type = 2'b11;
    else if (reset_signals_r[1])  // subsystem_rst
      reset_type = 2'b10;
    else if (reset_signals_r[0])  // local_rst
      reset_type = 2'b01;
    
    // Use a balanced structure for output determination
    case (reset_type)
      2'b11:   next_data = 8'h00;
      2'b10:   next_data = 8'h01;
      2'b01:   next_data = 8'h02;
      default: next_data = data_in_r;
    endcase
  end
  
  // Final output register
  always @(posedge clk) begin
    data_out <= next_data;
  end
endmodule