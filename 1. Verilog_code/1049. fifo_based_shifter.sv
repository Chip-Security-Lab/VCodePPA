module fifo_based_shifter #(parameter DEPTH=8, WIDTH=16) (
  input clk, rst_n,
  input [WIDTH-1:0] data_in,
  input push, pop,
  input [2:0] shift_amount,
  output [WIDTH-1:0] data_out
);
  reg [WIDTH-1:0] memory [0:DEPTH-1];
  reg [$clog2(DEPTH)-1:0] rd_ptr, wr_ptr;
  
  // Write with push
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
    end else if (push) begin
      memory[wr_ptr] <= data_in;
      wr_ptr <= wr_ptr + 1'b1;
    end
  end
  
  // Read with shifting
  assign data_out = memory[(rd_ptr + shift_amount) % DEPTH];
  
  // Update read pointer
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
    end else if (pop) begin
      rd_ptr <= rd_ptr + 1'b1;
    end
  end
endmodule