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
  
  // Write pointer control
  always @(posedge wr_clk or negedge reset_n) begin
    if (!reset_n)
      wr_ptr <= 0;
    else if (write_en && !full)
      wr_ptr <= wr_ptr + 1'b1;
  end

  // Write data control  
  always @(posedge wr_clk) begin
    if (write_en && !full)
      buffer[wr_ptr] <= data_in;
  end

  // Write count control
  always @(posedge wr_clk or negedge reset_n) begin
    if (!reset_n)
      count <= 0;
    else if (write_en && !full && !(read_en && !empty))
      count <= count + 1'b1;
    else if (!write_en && read_en && !empty)
      count <= count - 1'b1;
  end

  // Read pointer control
  always @(posedge rd_clk or negedge reset_n) begin
    if (!reset_n)
      rd_ptr <= 0;
    else if (read_en && !empty)
      rd_ptr <= rd_ptr + 1'b1;
  end

  // Read data control
  always @(posedge rd_clk) begin
    if (read_en && !empty)
      data_out <= buffer[rd_ptr];
    else if (!reset_n)
      data_out <= 0;
  end

  // Status signals
  assign empty = ~|count;
  assign full = &count[$clog2(DEPTH)-1:0];
  
  // Fill level
  always @(*) begin
    fill_level = count;
  end

endmodule