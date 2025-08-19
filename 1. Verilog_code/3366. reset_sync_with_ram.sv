module reset_sync_with_ram #(parameter ADDR_WIDTH = 2) (
  input  wire                    clk,
  input  wire                    rst_n,
  output wire                    synced, // 改为wire以匹配连续赋值
  output reg  [2**ADDR_WIDTH-1:0] mem_data
);
  reg flop;
  
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      flop     <= 1'b0;
      mem_data <= { (2**ADDR_WIDTH) {1'b0} };
    end else begin
      flop     <= 1'b1;
      mem_data <= { (2**ADDR_WIDTH) {1'b1} };
    end
  end
  
  assign synced = flop;
endmodule