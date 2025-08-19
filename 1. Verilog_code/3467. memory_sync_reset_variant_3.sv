//SystemVerilog
module memory_sync_reset #(
  parameter DEPTH = 8,
  parameter WIDTH = 8
)(
  input wire clk,
  input wire reset,
  input wire [WIDTH-1:0] data_in,
  input wire [$clog2(DEPTH)-1:0] addr,
  input wire write_en,
  output reg [WIDTH-1:0] data_out
);
  // Memory array declaration
  reg [WIDTH-1:0] mem [0:DEPTH-1];
  
  // Registered control signals for better timing
  reg write_en_reg;
  reg [$clog2(DEPTH)-1:0] addr_reg;
  reg [WIDTH-1:0] data_in_reg;
  reg reset_reg;
  
  // Register input signals to reduce input-to-register delay
  always @(posedge clk) begin
    write_en_reg <= write_en;
    addr_reg <= addr;
    data_in_reg <= data_in;
    reset_reg <= reset;
  end
  
  // Read operation with registered control signals
  always @(posedge clk) begin
    if (!reset_reg && !write_en_reg) begin
      data_out <= mem[addr_reg];
    end
    else if (reset_reg) begin
      data_out <= {WIDTH{1'b0}};
    end
  end
  
  // Write operation with registered control signals
  integer i;
  always @(posedge clk) begin
    if (reset_reg) begin
      // Parallel reset using generate block structure for better synthesis
      for (i = 0; i < DEPTH; i = i + 1) begin : reset_loop
        mem[i] <= {WIDTH{1'b0}};
      end
    end
    else if (write_en_reg) begin
      mem[addr_reg] <= data_in_reg;
    end
  end
endmodule