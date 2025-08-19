//SystemVerilog
module fifo_based_shifter #(parameter DEPTH=8, WIDTH=16) (
  input clk, rst_n,
  input [WIDTH-1:0] data_in,
  input push, pop,
  input [2:0] shift_amount,
  output [WIDTH-1:0] data_out
);

  // Internal FIFO memory
  reg [WIDTH-1:0] fifo_mem [0:DEPTH-1];

  // Pointer and control registers
  reg [$clog2(DEPTH)-1:0] wr_ptr_reg, rd_ptr_reg;
  reg [$clog2(DEPTH)-1:0] wr_ptr_next, rd_ptr_next;
  reg [2:0] shift_amt_reg;
  reg [WIDTH-1:0] data_in_reg;
  reg push_reg, pop_reg;
  reg [WIDTH-1:0] data_out_reg;

  // Input registering
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      data_in_reg <= {WIDTH{1'b0}};
    else
      data_in_reg <= data_in;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      push_reg <= 1'b0;
    else
      push_reg <= push;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      pop_reg <= 1'b0;
    else
      pop_reg <= pop;
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      shift_amt_reg <= 3'd0;
    else
      shift_amt_reg <= shift_amount;
  end

  // Write pointer logic (flattened control)
  always @(*) begin
    if (push_reg)
      wr_ptr_next = wr_ptr_reg + 1'b1;
    else
      wr_ptr_next = wr_ptr_reg;
  end

  // Read pointer logic (flattened control)
  always @(*) begin
    if (pop_reg)
      rd_ptr_next = rd_ptr_reg + 1'b1;
    else
      rd_ptr_next = rd_ptr_reg;
  end

  // Write pointer register update (flattened)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      wr_ptr_reg <= {($clog2(DEPTH)){1'b0}};
    else
      wr_ptr_reg <= wr_ptr_next;
  end

  // Read pointer register update (flattened)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      rd_ptr_reg <= {($clog2(DEPTH)){1'b0}};
    else
      rd_ptr_reg <= rd_ptr_next;
  end

  // FIFO memory write (flattened)
  always @(posedge clk) begin
    if (push_reg)
      fifo_mem[wr_ptr_reg] <= data_in_reg;
  end

  // Data output register update (flattened)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      data_out_reg <= {WIDTH{1'b0}};
    else
      data_out_reg <= fifo_mem[(rd_ptr_reg + shift_amt_reg) % DEPTH];
  end

  assign data_out = data_out_reg;

endmodule