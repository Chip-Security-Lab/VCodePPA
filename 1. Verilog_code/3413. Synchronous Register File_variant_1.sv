//SystemVerilog
module RD3 #(parameter AW=2, DW=8)(
  input clk, input rst,
  input [AW-1:0] addr,
  input wr_en,
  input [DW-1:0] wdata,
  output reg [DW-1:0] rdata
);
  reg [DW-1:0] mem [0:(1<<AW)-1];
  wire [DW-1:0] complemented_data;
  wire [DW-1:0] subtraction_result;
  wire subtraction_en;
  
  // Register buffers for high fanout signals
  reg [DW-1:0] wdata_buf1, wdata_buf2;
  reg [DW-1:0] mem_buf1, mem_buf2;
  reg subtraction_en_buf1, subtraction_en_buf2;
  
  // Pipeline registers for fanout reduction
  always @(posedge clk) begin
    // Buffer for wdata (high fanout data bus)
    wdata_buf1 <= wdata;
    wdata_buf2 <= wdata_buf1;
    
    // Buffer for memory read data (high fanout)
    mem_buf1 <= mem[addr];
    mem_buf2 <= mem_buf1;
    
    // Buffer for subtraction enable (control signal with high fanout)
    subtraction_en_buf1 <= wdata_buf1[DW-1]; // MSB indicates subtraction operation
    subtraction_en_buf2 <= subtraction_en_buf1;
  end
  
  // Two's complement implementation for subtraction
  assign subtraction_en = wdata_buf1[DW-1]; // MSB indicates subtraction operation
  assign complemented_data = subtraction_en ? (~wdata_buf1[DW-2:0] + 1'b1) : wdata_buf1[DW-2:0];
  assign subtraction_result = {subtraction_en, complemented_data[DW-2:0]};
  
  integer i;
  always @(posedge clk) begin
    if (rst)
      for (i=0; i<(1<<AW); i=i+1) mem[i] <= 0;
    else if (wr_en)
      mem[addr] <= subtraction_result;
    rdata <= mem_buf1; // Use buffered memory read to reduce fanout
  end
endmodule