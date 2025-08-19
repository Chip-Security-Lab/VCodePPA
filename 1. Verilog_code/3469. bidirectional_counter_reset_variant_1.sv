//SystemVerilog
module bidirectional_counter_reset #(parameter WIDTH = 8)(
  input clk, reset, up_down, load, enable,
  input [WIDTH-1:0] data_in,
  output reg [WIDTH-1:0] count
);
  // 流水线寄存器
  reg [WIDTH-1:0] count_stage1, count_stage2;
  reg up_down_stage1, load_stage1, enable_stage1;
  reg [WIDTH-1:0] data_in_stage1;
  
  // 流水线控制信号
  reg valid_stage1, valid_stage2;
  
  // 第一级：输入采样和控制信号处理
  always @(posedge clk) begin
    if (reset) begin
      up_down_stage1 <= 1'b0;
      load_stage1 <= 1'b0;
      enable_stage1 <= 1'b0;
      data_in_stage1 <= {WIDTH{1'b0}};
      count_stage1 <= {WIDTH{1'b0}};
      valid_stage1 <= 1'b0;
    end
    else begin
      up_down_stage1 <= up_down;
      load_stage1 <= load;
      enable_stage1 <= enable;
      data_in_stage1 <= data_in;
      count_stage1 <= count;
      valid_stage1 <= 1'b1;
    end
  end
  
  // 第二级：计算逻辑处理
  always @(posedge clk) begin
    if (reset) begin
      count_stage2 <= {WIDTH{1'b0}};
      valid_stage2 <= 1'b0;
    end
    else if (valid_stage1) begin
      if (load_stage1)
        count_stage2 <= data_in_stage1;
      else if (enable_stage1) begin
        if (up_down_stage1)
          count_stage2 <= count_stage1 + 1'b1;
        else
          count_stage2 <= count_stage1 - 1'b1;
      end
      else
        count_stage2 <= count_stage1;
      
      valid_stage2 <= valid_stage1;
    end
  end
  
  // 第三级：输出更新
  always @(posedge clk) begin
    if (reset) begin
      count <= {WIDTH{1'b0}};
    end
    else if (valid_stage2) begin
      count <= count_stage2;
    end
  end
endmodule