//SystemVerilog
module mipi_slimbus_cdc (
  input wire src_clk, dst_clk, reset_n,
  input wire [31:0] data_in,
  input wire valid_in,
  output reg [31:0] data_out,
  output reg valid_out
);

  // FIFO memory
  reg [31:0] fifo [0:3];
  
  // Source domain pointers
  reg [1:0] wr_ptr_src;
  reg [1:0] wr_ptr_gray;
  reg [1:0] wr_ptr_gray_stage1;
  reg [1:0] wr_ptr_gray_stage2;
  
  // Destination domain pointers
  reg [1:0] rd_ptr_dst;
  reg [1:0] rd_ptr_gray;
  reg [1:0] rd_ptr_gray_stage1;
  reg [1:0] rd_ptr_gray_stage2;
  
  // Pipeline control signals
  reg valid_stage1, valid_stage2;
  reg [31:0] data_stage1, data_stage2;
  
  // Gray code conversion functions
  function automatic [1:0] bin2gray;
    input [1:0] bin;
    return bin ^ (bin >> 1);
  endfunction
  
  function automatic [1:0] gray2bin;
    input [1:0] gray;
    return gray ^ (gray >> 1);
  endfunction
  
  // Source domain pipeline stage 1
  always @(posedge src_clk or negedge reset_n) begin
    if (!reset_n) begin
      wr_ptr_src <= 2'd0;
      wr_ptr_gray <= 2'd0;
      valid_stage1 <= 1'b0;
    end else if (valid_in) begin
      fifo[wr_ptr_src] <= data_in;
      wr_ptr_src <= wr_ptr_src + 1'b1;
      wr_ptr_gray <= bin2gray(wr_ptr_src + 1'b1);
      valid_stage1 <= 1'b1;
      data_stage1 <= data_in;
    end else begin
      valid_stage1 <= 1'b0;
    end
  end
  
  // Source domain pipeline stage 2
  always @(posedge src_clk or negedge reset_n) begin
    if (!reset_n) begin
      wr_ptr_gray_stage1 <= 2'd0;
      wr_ptr_gray_stage2 <= 2'd0;
      valid_stage2 <= 1'b0;
    end else begin
      wr_ptr_gray_stage1 <= wr_ptr_gray;
      wr_ptr_gray_stage2 <= wr_ptr_gray_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Destination domain pipeline stage 1
  always @(posedge dst_clk or negedge reset_n) begin
    if (!reset_n) begin
      rd_ptr_gray <= 2'd0;
      rd_ptr_gray_stage1 <= 2'd0;
      rd_ptr_gray_stage2 <= 2'd0;
    end else begin
      rd_ptr_gray <= rd_ptr_dst;
      rd_ptr_gray_stage1 <= rd_ptr_gray;
      rd_ptr_gray_stage2 <= rd_ptr_gray_stage1;
    end
  end
  
  // Destination domain pipeline stage 2
  always @(posedge dst_clk or negedge reset_n) begin
    if (!reset_n) begin
      rd_ptr_dst <= 2'd0;
      data_out <= 32'd0;
      valid_out <= 1'b0;
    end else if (valid_stage2 && (rd_ptr_dst != gray2bin(wr_ptr_gray_stage2))) begin
      data_out <= fifo[rd_ptr_dst];
      rd_ptr_dst <= rd_ptr_dst + 1'b1;
      valid_out <= 1'b1;
    end else begin
      valid_out <= 1'b0;
    end
  end

endmodule