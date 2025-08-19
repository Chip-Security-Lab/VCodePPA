//SystemVerilog
module can_id_matcher #(
  parameter NUM_PATTERNS = 8
)(
  input wire clk, rst_n,
  input wire [10:0] rx_id,
  input wire id_valid,
  input wire [10:0] match_patterns [0:NUM_PATTERNS-1],
  input wire [NUM_PATTERNS-1:0] pattern_enable,
  output reg id_match,
  output reg [NUM_PATTERNS-1:0] pattern_matched,
  output reg [7:0] match_index
);
  
  // 预存寄存器的RX_ID和ID_VALID信号
  reg [10:0] rx_id_reg;
  reg id_valid_reg;
  reg [NUM_PATTERNS-1:0] pattern_enable_reg;
  
  // 将输入信号寄存
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_id_reg <= 0;
      id_valid_reg <= 0;
      pattern_enable_reg <= 0;
    end else begin
      rx_id_reg <= rx_id;
      id_valid_reg <= id_valid;
      pattern_enable_reg <= pattern_enable;
    end
  end
  
  // 直接计算比较结果并输出，不再使用中间寄存器
  // 这样将寄存器从输出端向后拉移到了输入端
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_match <= 0;
      pattern_matched <= 0;
      match_index <= 0;
    end else begin
      if (id_valid_reg) begin
        // 计算匹配逻辑
        id_match <= 0;
        pattern_matched <= 0;
        match_index <= 0;
        
        for (integer i = 0; i < NUM_PATTERNS; i = i + 1) begin
          if (pattern_enable_reg[i] && (rx_id_reg == match_patterns[i])) begin
            pattern_matched[i] <= 1;
            id_match <= 1;
            match_index <= i;
          end
        end
      end else begin
        id_match <= 0;
        pattern_matched <= 0;
        // 保持match_index不变，因为只有当id_match为1时它才有效
      end
    end
  end
  
endmodule