//SystemVerilog
module hamming_code_gen(
  input wire clk,            // 时钟输入
  input wire rst_n,          // 低电平有效复位
  input wire [3:0] data_in,  // 4位输入数据
  input wire data_valid,     // 输入数据有效信号
  output reg [6:0] hamming_out, // 7位汉明码输出
  output reg code_valid      // 输出码字有效信号
);

  // 内部信号定义
  reg [3:0] data_in_r;          // 数据输入寄存器
  reg data_valid_r;             // 数据有效寄存器
  reg [2:0] parity_bits;        // 奇偶校验位
  reg [3:0] data_bits;          // 数据位寄存器
  
  // 用于并行计算奇偶校验的组合逻辑
  wire [2:0] parity_calc;

  // 优化的奇偶校验位计算逻辑 - 使用组合逻辑提前计算
  assign parity_calc[0] = data_in[0] ^ data_in[1] ^ data_in[3];  // P1
  assign parity_calc[1] = data_in[0] ^ data_in[2] ^ data_in[3];  // P2
  assign parity_calc[2] = data_in[1] ^ data_in[2] ^ data_in[3];  // P4

  // 第一级流水线 - 输入寄存
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_in_r <= 4'b0;
      data_valid_r <= 1'b0;
      parity_bits <= 3'b0;
      data_bits <= 4'b0;
    end else begin
      data_in_r <= data_in;
      data_valid_r <= data_valid;
      // 将奇偶校验计算移至第一级，减少关键路径
      if (data_valid) begin
        parity_bits <= parity_calc;
        data_bits <= data_in;
      end
    end
  end

  // 输出级流水线 - 形成完整的汉明码
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      hamming_out <= 7'b0;
      code_valid <= 1'b0;
    end else begin
      // 只在数据有效时更新输出
      if (data_valid_r) begin
        // 组装汉明码：使用位拼接操作来优化
        hamming_out <= {data_bits[3:1], parity_bits[2], data_bits[0], parity_bits[1:0]};
      end
      code_valid <= data_valid_r;
    end
  end

endmodule