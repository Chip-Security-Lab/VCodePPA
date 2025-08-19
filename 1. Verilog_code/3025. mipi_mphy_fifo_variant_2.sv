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

  // Memory array
  reg [WIDTH-1:0] fifo_mem [0:DEPTH-1];
  
  // Write domain pipeline registers
  reg [$clog2(DEPTH)-1:0] wr_ptr_stage1, wr_ptr_stage2;
  reg wr_valid_stage1, wr_valid_stage2;
  reg [WIDTH-1:0] wr_data_stage1, wr_data_stage2;
  
  // Read domain pipeline registers  
  reg [$clog2(DEPTH)-1:0] rd_ptr_stage1, rd_ptr_stage2;
  reg rd_valid_stage1, rd_valid_stage2;
  reg [WIDTH-1:0] rd_data_stage1, rd_data_stage2;
  
  // FIFO status
  reg [$clog2(DEPTH):0] fifo_count;
  reg [$clog2(DEPTH):0] fifo_count_next;
  
  // Write domain pipeline stage 1
  always @(posedge wr_clk or negedge reset_n) begin
    if (!reset_n) begin
      wr_ptr_stage1 <= 0;
      wr_valid_stage1 <= 0;
      wr_data_stage1 <= 0;
    end else begin
      wr_valid_stage1 <= write_en && !full;
      wr_data_stage1 <= data_in;
      wr_ptr_stage1 <= wr_ptr_stage1 + (write_en && !full);
    end
  end

  // Write domain pipeline stage 2
  always @(posedge wr_clk or negedge reset_n) begin
    if (!reset_n) begin
      wr_ptr_stage2 <= 0;
      wr_valid_stage2 <= 0;
      wr_data_stage2 <= 0;
    end else begin
      wr_valid_stage2 <= wr_valid_stage1;
      wr_data_stage2 <= wr_data_stage1;
      wr_ptr_stage2 <= wr_ptr_stage1;
    end
  end
  
  // Memory write
  always @(posedge wr_clk) begin
    if (wr_valid_stage2) begin
      fifo_mem[wr_ptr_stage2] <= wr_data_stage2;
    end
  end
  
  // Read domain pipeline stage 1
  always @(posedge rd_clk or negedge reset_n) begin
    if (!reset_n) begin
      rd_ptr_stage1 <= 0;
      rd_valid_stage1 <= 0;
      rd_data_stage1 <= 0;
    end else begin
      rd_valid_stage1 <= read_en && !empty;
      rd_ptr_stage1 <= rd_ptr_stage1 + (read_en && !empty);
      rd_data_stage1 <= fifo_mem[rd_ptr_stage1];
    end
  end

  // Read domain pipeline stage 2
  always @(posedge rd_clk or negedge reset_n) begin
    if (!reset_n) begin
      rd_ptr_stage2 <= 0;
      rd_valid_stage2 <= 0;
      rd_data_stage2 <= 0;
      data_out <= 0;
    end else begin
      rd_valid_stage2 <= rd_valid_stage1;
      rd_ptr_stage2 <= rd_ptr_stage1;
      rd_data_stage2 <= rd_data_stage1;
      data_out <= rd_data_stage1;
    end
  end
  
  // FIFO count management
  always @(posedge wr_clk or negedge reset_n) begin
    if (!reset_n) begin
      fifo_count <= 0;
    end else begin
      fifo_count <= fifo_count_next;
    end
  end
  
  // Count update logic
  always @(*) begin
    case ({wr_valid_stage2, rd_valid_stage2})
      2'b10: fifo_count_next = fifo_count + 1'b1;
      2'b01: fifo_count_next = fifo_count - 1'b1;
      default: fifo_count_next = fifo_count;
    endcase
  end
  
  // Status signals
  assign empty = (fifo_count == 0);
  assign full = (fifo_count == DEPTH);
  assign fill_level = fifo_count;
  
endmodule