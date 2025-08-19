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
  reg [$clog2(DEPTH)-1:0] wr_ptr_gray, rd_ptr_gray;
  reg [$clog2(DEPTH)-1:0] wr_ptr_sync, rd_ptr_sync;
  
  wire wr_en = write_en && !full;
  wire rd_en = read_en && !empty;
  
  // Write domain
  always @(posedge wr_clk or negedge reset_n) begin
    if (!reset_n) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
    end else if (wr_en) begin
      wr_ptr <= wr_ptr + 1'b1;
      wr_ptr_gray <= (wr_ptr + 1'b1) ^ ((wr_ptr + 1'b1) >> 1);
    end
  end

  // Read domain
  always @(posedge rd_clk or negedge reset_n) begin
    if (!reset_n) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
      data_out <= 0;
    end else if (rd_en) begin
      rd_ptr <= rd_ptr + 1'b1;
      rd_ptr_gray <= (rd_ptr + 1'b1) ^ ((rd_ptr + 1'b1) >> 1);
      data_out <= buffer[rd_ptr];
    end
  end

  // Pointer synchronization
  always @(posedge rd_clk or negedge reset_n) begin
    if (!reset_n) wr_ptr_sync <= 0;
    else wr_ptr_sync <= gray2bin(wr_ptr_gray);
  end

  always @(posedge wr_clk or negedge reset_n) begin
    if (!reset_n) rd_ptr_sync <= 0;
    else rd_ptr_sync <= gray2bin(rd_ptr_gray);
  end

  // Memory write
  always @(posedge wr_clk) begin
    if (wr_en) buffer[wr_ptr] <= data_in;
  end

  // Status signals
  wire [$clog2(DEPTH):0] wr_count = wr_ptr - rd_ptr_sync;
  wire [$clog2(DEPTH):0] rd_count = wr_ptr_sync - rd_ptr;
  
  assign empty = (rd_count == 0);
  assign full = (wr_count == DEPTH);

  // Fill level
  always @(posedge rd_clk or negedge reset_n) begin
    if (!reset_n) fill_level <= 0;
    else fill_level <= rd_count;
  end

  function [$clog2(DEPTH)-1:0] gray2bin;
    input [$clog2(DEPTH)-1:0] gray;
    reg [$clog2(DEPTH)-1:0] bin;
    integer i;
    begin
      bin = gray;
      for (i = 1; i < $clog2(DEPTH); i = i + 1)
        bin = bin ^ (gray >> i);
      gray2bin = bin;
    end
  endfunction

endmodule