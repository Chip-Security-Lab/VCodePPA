//SystemVerilog
`timescale 1ns / 1ps
`default_nettype none
// IEEE 1364-2005 Verilog标准

module prio_enc_fsm #(parameter WIDTH=6)(
  input wire clk, rst,
  input wire [WIDTH-1:0] in,
  output reg [$clog2(WIDTH)-1:0] addr
);
  // 使用参数化的位宽
  localparam IDLE = 1'b0;
  localparam SCAN = 1'b1;
  
  reg state;
  integer i;

  always @(posedge clk) begin
    if(rst) begin
      state <= IDLE;
      addr <= 0;
    end 
    else if(state == IDLE && |in) begin
      state <= SCAN;
      addr <= 0;
    end
    else if(state == SCAN) begin
      // 并行逻辑：扁平化的优先编码器
      addr <= 0; // 默认值
      for(i=0; i<WIDTH; i=i+1) begin
        if(in[i]) addr <= i[$clog2(WIDTH)-1:0];
      end
      state <= IDLE;
    end
    else begin
      // 默认情况：包括IDLE状态且in全为0的情况
      state <= IDLE;
    end
  end
endmodule