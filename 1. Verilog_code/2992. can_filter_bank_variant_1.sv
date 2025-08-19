//SystemVerilog
module can_filter_bank #(
  parameter NUM_FILTERS = 4
)(
  input wire clk, rst_n,
  input wire [10:0] rx_id,
  input wire id_valid,
  input wire [NUM_FILTERS-1:0] filter_enable,
  input wire [10:0] filter_id [0:NUM_FILTERS-1],
  input wire [10:0] filter_mask [0:NUM_FILTERS-1],
  output reg id_match,
  output reg [NUM_FILTERS-1:0] match_filter
);
  integer i;
  
  // 注册输入信号，前向寄存器重定时
  reg [10:0] rx_id_reg;
  reg id_valid_reg;
  reg [NUM_FILTERS-1:0] filter_enable_reg;
  reg [10:0] filter_id_reg [0:NUM_FILTERS-1];
  reg [10:0] filter_mask_reg [0:NUM_FILTERS-1];
  
  // 将输入信号寄存在组合逻辑之前
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_id_reg <= 0;
      id_valid_reg <= 0;
      filter_enable_reg <= 0;
      for (i = 0; i < NUM_FILTERS; i = i + 1) begin
        filter_id_reg[i] <= 0;
        filter_mask_reg[i] <= 0;
      end
    end else begin
      rx_id_reg <= rx_id;
      id_valid_reg <= id_valid;
      filter_enable_reg <= filter_enable;
      for (i = 0; i < NUM_FILTERS; i = i + 1) begin
        filter_id_reg[i] <= filter_id[i];
        filter_mask_reg[i] <= filter_mask[i];
      end
    end
  end
  
  // 组合逻辑使用寄存后的输入信号
  reg [NUM_FILTERS-1:0] match_results;
  reg match_any;
  
  always @(*) begin
    match_results = 0;
    match_any = 0;
    
    for (i = 0; i < NUM_FILTERS; i = i + 1) begin
      if (filter_enable_reg[i] && ((rx_id_reg & filter_mask_reg[i]) == (filter_id_reg[i] & filter_mask_reg[i]))) begin
        match_results[i] = 1;
        match_any = 1;
      end
    end
  end
  
  // 输出寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_match <= 0;
      match_filter <= 0;
    end else if (id_valid_reg) begin
      id_match <= match_any;
      match_filter <= match_results;
    end
  end
endmodule