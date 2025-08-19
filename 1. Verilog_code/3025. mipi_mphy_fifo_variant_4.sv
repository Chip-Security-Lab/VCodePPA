//SystemVerilog
module mipi_mphy_fifo #(
  parameter WIDTH = 32,
  parameter DEPTH = 16
)(
  input wire wr_clk, rd_clk, reset_n,
  input wire [WIDTH-1:0] data_in,
  input wire write_en, read_en,
  output reg [WIDTH-1:0] data_out,
  output wire empty, full,
  output reg [4:0] fill_level
);

  reg [WIDTH-1:0] buffer [0:DEPTH-1];
  reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
  reg [$clog2(DEPTH):0] count;
  
  // Write domain with optimized control logic
  wire wr_enable = write_en && !full;
  
  always @(posedge wr_clk or negedge reset_n) begin
    if (!reset_n) begin
      wr_ptr <= 0;
    end else if (wr_enable) begin
      buffer[wr_ptr] <= data_in;
      wr_ptr <= wr_ptr + 1'b1;
    end
  end
  
  // Read domain with optimized control logic
  wire rd_enable = read_en && !empty;
  
  always @(posedge rd_clk or negedge reset_n) begin
    if (!reset_n) begin
      rd_ptr <= 0;
      data_out <= 0;
    end else if (rd_enable) begin
      data_out <= buffer[rd_ptr];
      rd_ptr <= rd_ptr + 1'b1;
    end
  end
  
  // Optimized fill level calculation with balanced logic
  wire [4:0] wr_ptr_ext = {1'b0, wr_ptr};
  wire [4:0] rd_ptr_ext = {1'b0, rd_ptr};
  wire [4:0] fill_level_next = wr_ptr_ext - rd_ptr_ext;
  
  // Fill level update with optimized timing
  always @(posedge wr_clk or negedge reset_n) begin
    if (!reset_n) begin
      fill_level <= 0;
    end else begin
      fill_level <= fill_level_next;
    end
  end
  
  // Optimized status flags with balanced logic
  wire [4:0] fill_level_zero = {5{1'b0}};
  wire [4:0] fill_level_full = DEPTH;
  
  assign empty = (fill_level == fill_level_zero);
  assign full = (fill_level == fill_level_full);
  
endmodule