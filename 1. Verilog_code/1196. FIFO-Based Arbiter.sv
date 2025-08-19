module fifo_arbiter(
  input clk, rst_n,
  input [3:0] request,
  input new_req,
  output reg [3:0] grant,
  output empty
);
  reg [3:0] fifo [0:3];  // Simple FIFO to store requests
  reg [1:0] wr_ptr, rd_ptr;
  
  assign empty = (wr_ptr == rd_ptr);
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0; rd_ptr <= 0;
      grant <= 0;
    end else begin
      if (new_req) begin
        fifo[wr_ptr] <= request;
        wr_ptr <= wr_ptr + 1;
      end
      
      if (!empty) begin
        grant <= fifo[rd_ptr];
        rd_ptr <= rd_ptr + 1;
      end else grant <= 0;
    end
  end
endmodule