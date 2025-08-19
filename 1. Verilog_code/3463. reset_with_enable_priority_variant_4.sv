//SystemVerilog
module reset_with_enable_priority #(parameter WIDTH = 4)(
  input clk, rst, en,
  output reg [WIDTH-1:0] data_out
);
  // 计算下一个值的组合逻辑部分(提前计算)
  wire [WIDTH-1:0] next_data_value;
  assign next_data_value = internal_data_stage1 + 1'b1;
  
  // 第一级流水线寄存器
  reg [WIDTH-1:0] internal_data_stage1;
  reg valid_stage1;
  
  // 第二级流水线寄存器
  reg [WIDTH-1:0] internal_data_stage2;
  reg valid_stage2;
  
  // 第一级流水线 - 重定时：寄存器移到组合逻辑之后
  always @(posedge clk) begin
    if (rst) begin
      internal_data_stage1 <= {WIDTH{1'b0}};
      valid_stage1 <= 1'b0;
    end
    else begin
      if (en) begin
        internal_data_stage1 <= next_data_value; // 使用提前计算的值
        valid_stage1 <= 1'b1;
      end
      else begin
        valid_stage1 <= 1'b0;
      end
    end
  end
  
  // 第二级流水线 - 传输数据
  always @(posedge clk) begin
    if (rst) begin
      internal_data_stage2 <= {WIDTH{1'b0}};
      valid_stage2 <= 1'b0;
    end
    else begin
      internal_data_stage2 <= internal_data_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // 输出寄存器 - 最终输出
  always @(posedge clk) begin
    if (rst) begin
      data_out <= {WIDTH{1'b0}};
    end
    else if (valid_stage2) begin
      data_out <= internal_data_stage2;
    end
  end
endmodule