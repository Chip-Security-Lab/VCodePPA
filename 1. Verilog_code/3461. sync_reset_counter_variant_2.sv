//SystemVerilog
// Top-level module that integrates all components
module sync_reset_counter #(parameter WIDTH = 8)(
  input clk, rst_n, enable,
  output [WIDTH-1:0] count
);
  // Internal signals for connections between submodules
  wire enable_synced;
  wire [WIDTH-1:0] next_count_value;
  
  // Submodule for input synchronization
  enable_synchronizer enable_sync_inst (
    .clk(clk),
    .rst_n(rst_n),
    .enable_in(enable),
    .enable_out(enable_synced)
  );
  
  // Submodule for next count calculation
  next_count_logic #(
    .WIDTH(WIDTH)
  ) count_logic_inst (
    .current_count(count),
    .enable(enable_synced),
    .next_count(next_count_value)
  );
  
  // Submodule for count register with reset
  count_register #(
    .WIDTH(WIDTH)
  ) count_reg_inst (
    .clk(clk),
    .rst_n(rst_n),
    .next_count(next_count_value),
    .count(count)
  );
  
endmodule

// Submodule for input synchronization/retiming
module enable_synchronizer (
  input clk, rst_n, enable_in,
  output reg enable_out
);
  // Reset logic in a separate always block
  always @(posedge clk) begin
    if (!rst_n)
      enable_out <= 1'b0;
  end
  
  // Normal operation logic in separate always block
  always @(posedge clk) begin
    if (rst_n)
      enable_out <= enable_in;
  end
endmodule

// Submodule for next count calculation logic
module next_count_logic #(parameter WIDTH = 8)(
  input [WIDTH-1:0] current_count,
  input enable,
  output reg [WIDTH-1:0] next_count
);
  // Increment logic in separate always block
  always @(*) begin
    next_count = current_count;
  end
  
  // Enable logic in separate always block
  always @(*) begin
    if (enable)
      next_count = current_count + 1'b1;
  end
endmodule

// Submodule for count register with reset
module count_register #(parameter WIDTH = 8)(
  input clk, rst_n,
  input [WIDTH-1:0] next_count,
  output reg [WIDTH-1:0] count
);
  // Reset logic in separate always block
  always @(posedge clk) begin
    if (!rst_n)
      count <= {WIDTH{1'b0}};
  end
  
  // Update logic in separate always block
  always @(posedge clk) begin
    if (rst_n)
      count <= next_count;
  end
endmodule