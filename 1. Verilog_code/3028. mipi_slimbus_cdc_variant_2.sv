//SystemVerilog
module mipi_slimbus_cdc (
  input wire src_clk, dst_clk, reset_n,
  input wire [31:0] data_in,
  input wire valid_in,
  output reg [31:0] data_out,
  output reg valid_out
);

  // FIFO memory and pointers
  reg [31:0] fifo [0:3];
  reg [1:0] wr_ptr_src, rd_ptr_dst;
  reg [1:0] wr_ptr_gray, rd_ptr_gray;
  reg [1:0] wr_ptr_sync, rd_ptr_sync;
  
  // Gray code conversion functions - optimized
  function [1:0] bin2gray;
    input [1:0] bin;
    begin
      bin2gray = {bin[1], bin[0] ^ bin[1]};
    end
  endfunction
  
  function [1:0] gray2bin;
    input [1:0] gray;
    begin
      gray2bin = {gray[1], gray[0] ^ gray[1]};
    end
  endfunction
  
  // Source domain: FIFO write pointer management - optimized
  always @(posedge src_clk or negedge reset_n) begin
    if (!reset_n) begin
      wr_ptr_src <= 2'd0;
    end else if (valid_in) begin
      wr_ptr_src <= wr_ptr_src + 1'b1;
    end
  end
  
  // Source domain: FIFO write data and gray code conversion - optimized
  always @(posedge src_clk) begin
    if (valid_in) begin
      fifo[wr_ptr_src] <= data_in;
      wr_ptr_gray <= bin2gray(wr_ptr_src + 1'b1);
    end
  end
  
  // Destination domain: Synchronization of write pointer
  always @(posedge dst_clk) begin
    rd_ptr_sync <= wr_ptr_gray;
  end
  
  // Destination domain: FIFO read pointer management - optimized
  wire [1:0] rd_ptr_next = rd_ptr_dst + 1'b1;
  wire [1:0] rd_ptr_sync_bin = gray2bin(rd_ptr_sync);
  wire ptr_mismatch = (rd_ptr_sync_bin != rd_ptr_dst);
  
  always @(posedge dst_clk or negedge reset_n) begin
    if (!reset_n) begin
      rd_ptr_dst <= 2'd0;
      rd_ptr_gray <= 2'd0;
    end else if (ptr_mismatch) begin
      rd_ptr_dst <= rd_ptr_next;
      rd_ptr_gray <= bin2gray(rd_ptr_next);
    end
  end
  
  // Destination domain: Data output and valid signal generation - optimized
  always @(posedge dst_clk or negedge reset_n) begin
    if (!reset_n) begin
      data_out <= 32'd0;
      valid_out <= 1'b0;
    end else begin
      if (ptr_mismatch) begin
        data_out <= fifo[rd_ptr_dst];
        valid_out <= 1'b1;
      end else begin
        valid_out <= 1'b0;
      end
    end
  end

endmodule