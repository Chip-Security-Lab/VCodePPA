//SystemVerilog
module can_message_filter(
  input wire clk, rst_n,
  input wire [10:0] rx_id,
  input wire id_valid,
  input wire [10:0] filter_masks [0:3],
  input wire [10:0] filter_values [0:3],
  input wire [3:0] filter_enable,
  output reg frame_accepted
);
  reg [3:0] match_reg;
  wire [3:0] match_comb;
  
  // 并行计算所有匹配结果，减少组合逻辑延迟
  assign match_comb[0] = filter_enable[0] && ((rx_id & filter_masks[0]) == filter_values[0]);
  assign match_comb[1] = filter_enable[1] && ((rx_id & filter_masks[1]) == filter_values[1]);
  assign match_comb[2] = filter_enable[2] && ((rx_id & filter_masks[2]) == filter_values[2]);
  assign match_comb[3] = filter_enable[3] && ((rx_id & filter_masks[3]) == filter_values[3]);
  
  // 使用非阻塞赋值确保正确的时序行为
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      match_reg <= 4'b0;
      frame_accepted <= 1'b0;
    end else if (id_valid) begin
      match_reg <= match_comb;
      frame_accepted <= |match_comb; // 使用按位或操作，减少逻辑深度
    end
  end
endmodule