//SystemVerilog
module param_odd_parity_reg #(
  parameter DATA_W = 32
)(
  input clk,
  input [DATA_W-1:0] data,
  output reg parity_bit
);
  
  // 使用分组逐级计算奇偶校验，减少逻辑深度
  reg [DATA_W/2-1:0] partial_parity_1;
  reg [DATA_W/4-1:0] partial_parity_2;
  reg [DATA_W/8-1:0] partial_parity_3;
  reg final_parity;
  
  always @(posedge clk) begin
    // 第一级分组计算
    for (integer i = 0; i < DATA_W/2; i = i + 1) begin
      partial_parity_1[i] <= data[2*i] ^ data[2*i+1];
    end
    
    // 第二级分组计算
    for (integer i = 0; i < DATA_W/4; i = i + 1) begin
      partial_parity_2[i] <= partial_parity_1[2*i] ^ partial_parity_1[2*i+1];
    end
    
    // 第三级分组计算
    for (integer i = 0; i < DATA_W/8; i = i + 1) begin
      partial_parity_3[i] <= partial_parity_2[2*i] ^ partial_parity_2[2*i+1];
    end
    
    // 最终计算
    final_parity <= ^partial_parity_3;
    
    // 奇校验输出
    parity_bit <= ~final_parity;
  end
endmodule