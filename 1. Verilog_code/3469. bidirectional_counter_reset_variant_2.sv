//SystemVerilog
module bidirectional_counter_reset #(parameter WIDTH = 8)(
  input clk, reset, up_down, load, enable,
  input [WIDTH-1:0] data_in,
  output reg [WIDTH-1:0] count
);
  // Pipeline registers to reduce critical path
  reg up_down_reg, load_reg, enable_reg;
  reg [WIDTH-1:0] data_in_reg;
  reg [WIDTH-1:0] next_count;
  
  // Control signals registration
  always @(posedge clk) begin
    up_down_reg <= up_down;
    load_reg <= load;
    enable_reg <= enable;
    data_in_reg <= data_in;
  end
  
  // Calculate next count value (separate combinational logic)
  always @(*) begin
    if (load_reg)
      next_count = data_in_reg;
    else if (enable_reg)
      next_count = up_down_reg ? count + 1'b1 : count - 1'b1;
    else
      next_count = count;
  end
  
  // Update count register
  always @(posedge clk) begin
    if (reset)
      count <= {WIDTH{1'b0}};
    else
      count <= next_count;
  end
endmodule