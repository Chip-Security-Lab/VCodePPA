//SystemVerilog - IEEE 1364-2005
module RD3 #(parameter AW=2, DW=8)(
  input wire clk,
  input wire rst,
  input wire [AW-1:0] addr,
  input wire wr_en,
  input wire [DW-1:0] wdata,
  output reg [DW-1:0] rdata
);

  // Memory array declaration
  reg [DW-1:0] mem [0:(1<<AW)-1];
  
  // Buffered memory signals for high fanout reduction
  reg [DW-1:0] mem_buf1 [0:(1<<AW)-1];
  reg [DW-1:0] mem_buf2 [0:(1<<AW)-1];
  
  // Registered input signals for timing optimization
  reg [AW-1:0] addr_reg;
  reg wr_en_reg;
  reg [DW-1:0] wdata_reg;
  
  // Register input signals (forward retiming)
  always @(posedge clk) begin
    addr_reg <= addr;
    wr_en_reg <= wr_en;
    wdata_reg <= wdata;
  end
  
  // Reset and write operation with registered inputs
  integer i;
  always @(posedge clk) begin
    if (rst) begin
      for (i=0; i<(1<<AW); i=i+1) begin
        mem[i] <= {DW{1'b0}};
      end
    end else if (wr_en_reg) begin
      mem[addr_reg] <= wdata_reg;
    end
  end
  
  // Memory buffer stage 1 - distribute fanout load
  integer j;
  always @(posedge clk) begin
    for (j=0; j<(1<<AW); j=j+1) begin
      mem_buf1[j] <= mem[j];
    end
  end
  
  // Memory buffer stage 2 - further distribute fanout load
  integer k;
  always @(posedge clk) begin
    for (k=0; k<(1<<AW); k=k+1) begin
      mem_buf2[k] <= mem_buf1[k];
    end
  end
  
  // Read operation with registered address and buffered memory
  // Using memory buffer to reduce fanout on mem
  always @(posedge clk) begin
    rdata <= mem_buf2[addr_reg];
  end

endmodule