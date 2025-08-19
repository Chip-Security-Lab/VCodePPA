//SystemVerilog
module mipi_slimbus_cdc_axi (
  input wire src_clk, dst_clk, reset_n,
  
  input wire [31:0] in_data,
  input wire in_valid,
  output reg in_ready,
  
  output reg [31:0] out_data,
  output reg out_valid,
  input wire out_ready
);

  reg [31:0] fifo [0:3];
  reg [1:0] wr_ptr_src, rd_ptr_dst;
  reg [1:0] wr_ptr_gray, rd_ptr_gray;
  reg [1:0] wr_ptr_sync, rd_ptr_sync;
  
  wire [1:0] next_wr_ptr_src;
  wire [1:0] next_rd_ptr_dst;
  wire [1:0] next_wr_ptr_gray;
  wire [1:0] next_rd_ptr_gray;
  
  wire fifo_not_full;
  wire fifo_not_empty;
  
  assign next_wr_ptr_src = wr_ptr_src + 1'b1;
  assign next_rd_ptr_dst = rd_ptr_dst + 1'b1;
  assign next_wr_ptr_gray = next_wr_ptr_src ^ (next_wr_ptr_src >> 1);
  assign next_rd_ptr_gray = next_rd_ptr_dst ^ (next_rd_ptr_dst >> 1);
  
  assign fifo_not_full = (wr_ptr_src != rd_ptr_sync);
  assign fifo_not_empty = (rd_ptr_dst != wr_ptr_sync);
  
  always @(posedge src_clk or negedge reset_n) begin
    if (!reset_n) begin
      wr_ptr_src <= 2'd0;
      wr_ptr_gray <= 2'd0;
      in_ready <= 1'b0;
    end else begin
      in_ready <= fifo_not_full;
      if (in_valid && fifo_not_full) begin
        fifo[wr_ptr_src] <= in_data;
        wr_ptr_src <= next_wr_ptr_src;
        wr_ptr_gray <= next_wr_ptr_gray;
      end
    end
  end

  always @(posedge src_clk or negedge reset_n) begin
    if (!reset_n) begin
      rd_ptr_sync <= 2'd0;
    end else begin
      rd_ptr_sync <= rd_ptr_gray;
    end
  end

  always @(posedge dst_clk or negedge reset_n) begin
    if (!reset_n) begin
      rd_ptr_dst <= 2'd0;
      rd_ptr_gray <= 2'd0;
      out_valid <= 1'b0;
      out_data <= 32'd0;
    end else begin
      if (out_valid && out_ready) begin
        out_valid <= 1'b0;
      end
      if (!out_valid && fifo_not_empty) begin
        out_data <= fifo[rd_ptr_dst];
        out_valid <= 1'b1;
        rd_ptr_dst <= next_rd_ptr_dst;
        rd_ptr_gray <= next_rd_ptr_gray;
      end
    end
  end

  always @(posedge dst_clk or negedge reset_n) begin
    if (!reset_n) begin
      wr_ptr_sync <= 2'd0;
    end else begin
      wr_ptr_sync <= wr_ptr_gray;
    end
  end

endmodule