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
  reg [10:0] rx_id_reg;
  reg id_valid_reg;
  reg [3:0] filter_enable_reg;
  reg [10:0] filter_masks_reg [0:3];
  reg [10:0] filter_values_reg [0:3];
  wire [3:0] match_comb;
  
  // 寄存输入信号，将寄存器前移到输入端
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_id_reg <= 11'b0;
      id_valid_reg <= 1'b0;
      filter_enable_reg <= 4'b0;
      filter_masks_reg[0] <= 11'b0;
      filter_masks_reg[1] <= 11'b0;
      filter_masks_reg[2] <= 11'b0;
      filter_masks_reg[3] <= 11'b0;
      filter_values_reg[0] <= 11'b0;
      filter_values_reg[1] <= 11'b0;
      filter_values_reg[2] <= 11'b0;
      filter_values_reg[3] <= 11'b0;
    end else begin
      rx_id_reg <= rx_id;
      id_valid_reg <= id_valid;
      filter_enable_reg <= filter_enable;
      filter_masks_reg[0] <= filter_masks[0];
      filter_masks_reg[1] <= filter_masks[1];
      filter_masks_reg[2] <= filter_masks[2];
      filter_masks_reg[3] <= filter_masks[3];
      filter_values_reg[0] <= filter_values[0];
      filter_values_reg[1] <= filter_values[1];
      filter_values_reg[2] <= filter_values[2];
      filter_values_reg[3] <= filter_values[3];
    end
  end
  
  // 基于寄存后的信号进行匹配计算
  generate
    genvar g;
    for (g = 0; g < 4; g = g + 1) begin : match_logic
      assign match_comb[g] = filter_enable_reg[g] && 
                            ((rx_id_reg & filter_masks_reg[g]) == filter_values_reg[g]);
    end
  endgenerate
  
  // 使用非阻塞赋值更新输出状态
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frame_accepted <= 1'b0;
    end else if (id_valid_reg) begin
      frame_accepted <= |match_comb; // 使用按位或操作代替匹配比较
    end
  end
endmodule