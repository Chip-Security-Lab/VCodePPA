//SystemVerilog
module async_reset_counter #(parameter WIDTH = 16)(
  input clk, rst_n, enable,
  input valid_in,
  output reg valid_out,
  output reg [WIDTH-1:0] counter
);
  // 内部信号定义
  // 阶段1：第一部分加法计算
  reg [WIDTH-1:0] counter_stage1;
  reg [(WIDTH/2)-1:0] carry_stage1;
  reg valid_stage1;
  
  // 阶段2：第二部分加法计算
  reg [WIDTH-1:0] counter_stage2;
  reg valid_stage2;
  
  // 生成和传播信号
  wire [WIDTH-1:0] carry_gen, carry_prop;
  wire [WIDTH:0] carry;
  wire [WIDTH-1:0] next_count;
  
  assign carry_gen = counter & {WIDTH{1'b1}};
  assign carry_prop = counter | {WIDTH{1'b1}};
  assign carry[0] = enable;
  
  // 加法器计算 - 分段实现
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin: carry_chain
      assign carry[i+1] = carry_gen[i] | (carry_prop[i] & carry[i]);
      assign next_count[i] = counter[i] ^ carry[i];
    end
  endgenerate
  
  // 第一级流水线 - 计算前半部分
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter_stage1 <= {WIDTH{1'b0}};
      carry_stage1 <= {(WIDTH/2){1'b0}};
      valid_stage1 <= 1'b0;
    end else begin
      if (enable && valid_in) begin
        counter_stage1 <= counter;
        carry_stage1 <= carry[WIDTH/2:1]; // 保存中间进位
        valid_stage1 <= valid_in;
      end else if (enable) begin
        valid_stage1 <= 1'b0;
      end
    end
  end
  
  // 第二级流水线 - 完成计算
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter_stage2 <= {WIDTH{1'b0}};
      valid_stage2 <= 1'b0;
    end else begin
      if (enable && valid_stage1) begin
        counter_stage2 <= next_count;
        valid_stage2 <= valid_stage1;
      end else if (enable) begin
        valid_stage2 <= 1'b0;
      end
    end
  end
  
  // 输出级 - 更新计数器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= {WIDTH{1'b0}};
      valid_out <= 1'b0;
    end else begin
      if (enable && valid_stage2) begin
        counter <= counter_stage2;
        valid_out <= valid_stage2;
      end else if (enable) begin
        valid_out <= 1'b0;
      end
    end
  end
endmodule