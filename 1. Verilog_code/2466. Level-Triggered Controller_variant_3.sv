//SystemVerilog
module level_triggered_intr_ctrl(
  input wire clock, reset_n,
  input wire [3:0] intr_level,
  input wire [3:0] intr_enable,
  output reg [1:0] intr_id,
  output reg intr_out
);
  reg [3:0] level_detect;
  wire [1:0] priority_id;
  
  // 优化的优先级编码器逻辑
  assign priority_id = level_detect[3] ? 2'd3 :
                       level_detect[2] ? 2'd2 :
                       level_detect[1] ? 2'd1 : 2'd0;
  
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      level_detect <= 4'h0;
      intr_id <= 2'h0;
      intr_out <= 1'b0;
    end else begin
      level_detect <= intr_level & intr_enable;
      intr_out <= |level_detect;
      intr_id <= priority_id;
    end
  end
endmodule