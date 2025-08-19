//SystemVerilog
`timescale 1ns / 1ps
//IEEE 1364-2005
module reset_sync_case(
  input  wire clk,
  input  wire rst_n,
  output reg  rst_out
);
  reg stage1, stage2;
  
  always @(posedge clk or negedge rst_n) begin
    stage1 <= !rst_n ? 1'b0 : 1'b1;
    stage2 <= !rst_n ? 1'b0 : stage1;
    rst_out <= !rst_n ? 1'b0 : stage2;
  end
endmodule