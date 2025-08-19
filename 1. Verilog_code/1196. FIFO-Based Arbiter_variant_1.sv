//SystemVerilog
module fifo_arbiter(
  input clk, rst_n,
  input [3:0] request,
  input new_req,
  output reg [3:0] grant,
  output empty
);
  // FIFO storage and pointers
  reg [3:0] fifo [0:3];
  reg [1:0] wr_ptr, rd_ptr;
  reg new_req_reg;
  reg [3:0] request_reg;
  
  // FIFO empty status
  assign empty = (wr_ptr == rd_ptr);
  
  // Input registration stage - move registers forward
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      new_req_reg <= 0;
      request_reg <= 0;
    end else begin
      new_req_reg <= new_req;
      request_reg <= request;
    end
  end
  
  // Parallel Prefix Adder (PPA) signals for pointer increment
  wire [1:0] wr_ptr_next, rd_ptr_next;
  
  // FIFO write and read control logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
      grant <= 0;
    end else begin
      if (new_req_reg) begin
        fifo[wr_ptr] <= request_reg;
        wr_ptr <= wr_ptr_next;
      end
      
      if (!empty) begin
        grant <= fifo[rd_ptr];
        rd_ptr <= rd_ptr_next;
      end else begin
        grant <= 0;
      end
    end
  end
  
  // Instantiate the Parallel Prefix Adders for pointer increments
  parallel_prefix_adder_2bit wr_adder(
    .a(wr_ptr),
    .b(2'b01),
    .sum(wr_ptr_next)
  );
  
  parallel_prefix_adder_2bit rd_adder(
    .a(rd_ptr),
    .b(2'b01),
    .sum(rd_ptr_next)
  );
endmodule

// Parallel Prefix Adder (Kogge-Stone) implementation for 2-bit addition
module parallel_prefix_adder_2bit(
  input [1:0] a,
  input [1:0] b,
  output [1:0] sum
);
  // Generate (G) and Propagate (P) signals
  wire [1:0] G, P;
  
  // First level - Generate and Propagate calculation
  assign G[0] = a[0] & b[0];
  assign P[0] = a[0] ^ b[0];
  assign G[1] = a[1] & b[1];
  assign P[1] = a[1] ^ b[1];
  
  // Carry calculation using prefix computation
  wire [1:0] C;
  assign C[0] = G[0];
  assign C[1] = G[1] | (P[1] & G[0]);
  
  // Final sum calculation
  assign sum[0] = P[0] ^ 1'b0;  // No carry-in, so use 0
  assign sum[1] = P[1] ^ C[0];
endmodule