//SystemVerilog
module hamming_code_gen(
  input wire clk,            // 添加时钟信号以支持流水线
  input wire rst_n,          // 添加复位信号
  input wire valid_in,       // 数据有效信号
  input wire [3:0] data_in,  // 输入数据
  output reg valid_out,      // 输出有效信号
  output reg [6:0] hamming_out // 汉明码输出
);

  // 第一级流水线信号 - 存储输入数据和计算部分校验位
  reg [3:0] data_stage1;
  reg valid_stage1;
  reg p0_stage1, p1_stage1;  // 计算部分校验位

  // 第二级流水线信号
  reg [3:0] data_stage2;
  reg valid_stage2;
  reg p0_stage2, p1_stage2;
  reg p3_stage2;             // 最终校验位计算
  
  // 流水线第一级：捕获输入数据并计算前两个校验位
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_stage1 <= 4'b0;
      valid_stage1 <= 1'b0;
      p0_stage1 <= 1'b0;
      p1_stage1 <= 1'b0;
    end else begin
      valid_stage1 <= valid_in;
      if (valid_in) begin
        data_stage1 <= data_in;
        // 分离校验位计算，减少关键路径长度
        p0_stage1 <= data_in[0] ^ data_in[1] ^ data_in[3];
        p1_stage1 <= data_in[0] ^ data_in[2] ^ data_in[3];
      end
    end
  end

  // 流水线第二级：传递数据并完成最后一个校验位计算
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_stage2 <= 4'b0;
      valid_stage2 <= 1'b0;
      p0_stage2 <= 1'b0;
      p1_stage2 <= 1'b0;
      p3_stage2 <= 1'b0;
    end else begin
      valid_stage2 <= valid_stage1;
      if (valid_stage1) begin
        data_stage2 <= data_stage1;
        p0_stage2 <= p0_stage1;
        p1_stage2 <= p1_stage1;
        // 计算最后一个校验位
        p3_stage2 <= data_stage1[1] ^ data_stage1[2] ^ data_stage1[3];
      end
    end
  end
  
  // 流水线第三级：组装最终的汉明码
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      hamming_out <= 7'b0;
      valid_out <= 1'b0;
    end else begin
      valid_out <= valid_stage2;
      if (valid_stage2) begin
        // 最终汉明码组装
        hamming_out <= {
          data_stage2[3],  // 数据位D3
          data_stage2[2],  // 数据位D2
          data_stage2[1],  // 数据位D1
          p3_stage2,       // 校验位P3
          data_stage2[0],  // 数据位D0
          p1_stage2,       // 校验位P1
          p0_stage2        // 校验位P0
        };
      end
    end
  end
  
endmodule