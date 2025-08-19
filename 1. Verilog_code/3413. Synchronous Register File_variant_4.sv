//SystemVerilog
module RD3 #(parameter AW=2, DW=8)(
  input clk, input rst,
  input [AW-1:0] addr,
  input wr_en,
  input [DW-1:0] wdata,
  output reg [DW-1:0] rdata
);
  // Memory array declaration
  reg [DW-1:0] mem [0:(1<<AW)-1];
  
  // Pipeline registers
  reg [AW-1:0] addr_pipe1;
  reg wr_en_pipe;
  reg [DW-1:0] wdata_pipe;
  reg [DW-1:0] read_data_pipe;
  
  // Reset initialization
  integer i;
  
  // Stage 1: Input registration and address capture
  always @(posedge clk) begin
    if (rst) begin
      addr_pipe1 <= {AW{1'b0}};
      wr_en_pipe <= 1'b0;
      wdata_pipe <= {DW{1'b0}};
    end else begin
      addr_pipe1 <= addr;
      wr_en_pipe <= wr_en;
      wdata_pipe <= wdata;
    end
  end
  
  // Stage 2: Memory write and read operations
  always @(posedge clk) begin
    if (rst) begin
      read_data_pipe <= {DW{1'b0}};
      // Initialize memory during reset
      for (i=0; i<(1<<AW); i=i+1) 
        mem[i] <= {DW{1'b0}};
    end else begin
      // Write operation with registered signals
      if (wr_en_pipe)
        mem[addr_pipe1] <= wdata_pipe;
      
      // Read operation with registered address
      read_data_pipe <= mem[addr_pipe1];
    end
  end
  
  // Stage 3: Output registration
  always @(posedge clk) begin
    if (rst)
      rdata <= {DW{1'b0}};
    else
      rdata <= read_data_pipe;
  end
endmodule