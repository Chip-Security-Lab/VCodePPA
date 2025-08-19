//SystemVerilog
module RD3 #(parameter AW=2, DW=8)(
  input clk, input rst,
  input [AW-1:0] addr,
  input wr_en,
  input [DW-1:0] wdata,
  output [DW-1:0] rdata
);

  reg [DW-1:0] mem [0:(1<<AW)-1];
  reg [AW-1:0] addr_reg;
  integer i;
  
  // Register the address for read operations
  always @(posedge clk) begin
    addr_reg <= addr;
  end
  
  // Memory reset logic
  always @(posedge clk) begin
    if (rst) begin
      for (i=0; i<(1<<AW); i=i+1) 
        mem[i] <= 0;
    end
  end
  
  // Memory write logic - separated from reset for better timing
  always @(posedge clk) begin
    if (!rst && wr_en) begin
      mem[addr] <= wdata;
    end
  end
  
  // Read data from memory using registered address
  assign rdata = mem[addr_reg];
  
endmodule