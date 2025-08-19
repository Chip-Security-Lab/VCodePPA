//SystemVerilog
module reset_sync_with_ram #(parameter ADDR_WIDTH = 2) (
  input  wire                     clk,
  input  wire                     rst_n,
  output wire                     synced,
  output reg  [2**ADDR_WIDTH-1:0] mem_data
);
  reg flop;
  
  always @(posedge clk or negedge rst_n) begin
    flop     <= rst_n ? 1'b1 : 1'b0;
    mem_data <= rst_n ? {(2**ADDR_WIDTH){1'b1}} : {(2**ADDR_WIDTH){1'b0}};
  end
  
  assign synced = flop;
endmodule