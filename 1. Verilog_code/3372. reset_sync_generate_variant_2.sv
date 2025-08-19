//SystemVerilog
module reset_sync_generate #(
  parameter NUM_STAGES = 2
)(
  input  wire clk,
  input  wire rst_n,
  output wire synced
);
  // 主同步链
  reg [NUM_STAGES-1:0] chain;
  
  // 在第一级使用条件运算符，减少条件评估复杂度
  always @(posedge clk or negedge rst_n) begin
    chain[0] <= rst_n ? 1'b1 : 1'b0;
  end
  
  // 为剩余阶段生成逻辑，使用条件运算符
  genvar i;
  generate
    for (i = 1; i < NUM_STAGES; i = i + 1) begin : sync_stages
      always @(posedge clk or negedge rst_n) begin
        chain[i] <= rst_n ? chain[i-1] : 1'b0;
      end
    end
  endgenerate
  
  // 直接从寄存器输出，减少额外逻辑
  assign synced = chain[NUM_STAGES-1];
endmodule