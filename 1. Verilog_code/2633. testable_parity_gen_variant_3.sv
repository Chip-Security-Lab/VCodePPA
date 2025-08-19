//SystemVerilog
module testable_parity_gen(
  input clk,              // 时钟信号
  input rst_n,            // 复位信号
  input [7:0] data_in,    // 输入数据
  input test_mode_en,     // 测试模式使能
  input test_parity_in,   // 测试奇偶校验输入
  output reg parity_out   // 奇偶校验输出
);

  // 内部信号定义
  reg [7:0] data_reg;           // 数据寄存器
  reg test_mode_reg;            // 测试模式寄存器
  reg test_parity_reg;          // 测试奇偶校验寄存器
  
  reg [3:0] lower_parity;       // 低4位奇偶校验
  reg [3:0] upper_parity;       // 高4位奇偶校验
  reg computed_parity;          // 计算得到的奇偶校验

  // 输入寄存器组
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_reg <= 8'b0;
    end else begin
      data_reg <= data_in;
    end
  end

  // 测试控制寄存器组
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      test_mode_reg <= 1'b0;
      test_parity_reg <= 1'b0;
    end else begin
      test_mode_reg <= test_mode_en;
      test_parity_reg <= test_parity_in;
    end
  end

  // 低4位奇偶校验计算
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      lower_parity <= 4'b0;
    end else begin
      lower_parity <= data_reg[0] ^ data_reg[1] ^ data_reg[2] ^ data_reg[3];
    end
  end

  // 高4位奇偶校验计算
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      upper_parity <= 4'b0;
    end else begin
      upper_parity <= data_reg[4] ^ data_reg[5] ^ data_reg[6] ^ data_reg[7];
    end
  end

  // 最终奇偶校验计算
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      computed_parity <= 1'b0;
    end else begin
      computed_parity <= lower_parity ^ upper_parity;
    end
  end

  // 输出选择逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      parity_out <= 1'b0;
    end else begin
      parity_out <= test_mode_reg ? test_parity_reg : computed_parity;
    end
  end

endmodule