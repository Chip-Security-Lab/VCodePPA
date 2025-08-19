module fifo_parity_gen(
  input clk, rst_n, wr_en, rd_en,
  input [7:0] data_in,
  output reg fifo_parity,
  output reg [3:0] fifo_count
);
  reg parity_accumulator;
  
  always @(posedge clk) begin
    if (!rst_n) begin
      fifo_count <= 4'b0000;
      parity_accumulator <= 1'b0;
      fifo_parity <= 1'b0;
    end else if (wr_en) begin
      fifo_count <= fifo_count + 1'b1;
      parity_accumulator <= parity_accumulator ^ (^data_in);
    end else if (rd_en && fifo_count > 0) begin
      fifo_count <= fifo_count - 1'b1;
      fifo_parity <= parity_accumulator;
    end
  end
endmodule