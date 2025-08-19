//SystemVerilog
module fifo_based_shifter #(parameter DEPTH=8, WIDTH=16) (
  input wire clk,
  input wire rst_n,
  input wire [WIDTH-1:0] data_in,
  input wire push,
  input wire pop,
  input wire [2:0] shift_amount,
  output wire [WIDTH-1:0] data_out
);
  localparam PTR_WIDTH = $clog2(DEPTH);

  reg [WIDTH-1:0] fifo_mem [0:DEPTH-1];
  reg [PTR_WIDTH-1:0] rd_ptr, wr_ptr;

  // Write pointer and memory update logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= {PTR_WIDTH{1'b0}};
    end else if (push) begin
      fifo_mem[wr_ptr] <= data_in;
      wr_ptr <= (wr_ptr + 1'b1) & (DEPTH-1);
    end
  end

  // Conditional Invert Subtractor for address calculation (3-bit)
  wire [2:0] a_ptr = rd_ptr[2:0];
  wire [2:0] b_shift = shift_amount[2:0];
  wire [2:0] b_shift_inv;
  wire       carry_in;
  wire [2:0] sum_addr;
  wire       carry_out;

  // Conditional inversion and carry-in for subtraction: a - b = a + (~b) + 1
  assign b_shift_inv = ~b_shift;
  assign carry_in = 1'b1;

  assign {carry_out, sum_addr} = {1'b0, a_ptr} + {1'b0, b_shift_inv} + carry_in;

  wire [PTR_WIDTH-1:0] fifo_addr = sum_addr[PTR_WIDTH-1:0] & (DEPTH-1);

  assign data_out = fifo_mem[fifo_addr];

  // Read pointer update logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= {PTR_WIDTH{1'b0}};
    end else if (pop) begin
      rd_ptr <= (rd_ptr + 1'b1) & (DEPTH-1);
    end
  end

endmodule