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
  // FIFO memory
  reg [WIDTH-1:0] buffer [0:DEPTH-1];
  reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
  reg [$clog2(DEPTH):0] count;
  
  // Write domain
  always @(posedge wr_clk or negedge reset_n) begin
    if (!reset_n) begin
      wr_ptr <= 0;
    end else if (write_en && !full) begin
      buffer[wr_ptr] <= data_in;
      wr_ptr <= wr_ptr + 1'b1;
    end
  end
  
  // Read domain
  always @(posedge rd_clk or negedge reset_n) begin
    if (!reset_n) begin
      rd_ptr <= 0;
      data_out <= 0;
    end else if (read_en && !empty) begin
      data_out <= buffer[rd_ptr];
      rd_ptr <= rd_ptr + 1'b1;
    end
  end
  
  assign empty = (count == 0);
  assign full = (count == DEPTH);
endmodule