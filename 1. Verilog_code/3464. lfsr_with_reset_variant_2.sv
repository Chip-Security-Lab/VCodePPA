//SystemVerilog
module lfsr_with_reset #(parameter WIDTH = 8)(
  input wire clk, 
  input wire async_rst, 
  input wire enable,
  output wire [WIDTH-1:0] lfsr_out
);
  // 内部寄存器 - 移动到组合逻辑之后
  reg [WIDTH-1:0] lfsr_reg;
  reg enable_reg;
  
  // 输出赋值
  assign lfsr_out = lfsr_reg;
  
  // 对输入信号进行寄存
  always @(posedge clk or posedge async_rst) begin
    if (async_rst) begin
      enable_reg <= 1'b0;
    end else begin
      enable_reg <= enable;
    end
  end
  
  // 定义中间变量以提高可读性
  wire tap_bit7 = lfsr_reg[7];
  wire tap_bit3 = lfsr_reg[3];
  wire tap_bit2 = lfsr_reg[2];
  wire tap_bit1 = lfsr_reg[1];
  
  // 分解反馈计算逻辑
  wire feedback_stage1 = tap_bit7 ^ tap_bit3;
  wire feedback_stage2 = feedback_stage1 ^ tap_bit2;
  wire feedback = feedback_stage2 ^ tap_bit1;
  
  // 定义移位后的值
  wire [WIDTH-1:0] next_lfsr = {lfsr_reg[WIDTH-2:0], feedback};

  // 主LFSR寄存器逻辑 - 移动到组合逻辑之后
  always @(posedge clk or posedge async_rst) begin
    if (async_rst) begin
      // 复位时设置非零种子值
      lfsr_reg <= 8'h01;
    end 
    else begin
      if (enable_reg) begin
        // 启用时更新LFSR
        lfsr_reg <= next_lfsr;
      end
      // 如果不启用，保持当前值
    end
  end
endmodule