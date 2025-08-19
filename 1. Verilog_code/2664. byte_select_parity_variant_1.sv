//SystemVerilog
module byte_select_parity(
  input clk,               // 时钟信号
  input rst_n,             // 复位信号，低电平有效
  input [31:0] data_word,  // 数据输入
  input [3:0] byte_enable, // 字节使能信号
  input valid_in,          // 输入数据有效信号
  output ready_out,        // 模块准备接收数据信号
  output reg [0:0] parity_out, // 奇偶校验输出 
  output reg valid_out,    // 输出数据有效信号
  input ready_in           // 下游模块准备接收数据信号
);
  
  // 内部信号
  reg [31:0] data_word_reg;
  reg [3:0] byte_enable_reg;
  reg calculating;
  
  // 握手状态机
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_word_reg <= 32'd0;
      byte_enable_reg <= 4'd0;
      calculating <= 1'b0;
      valid_out <= 1'b0;
      parity_out <= 1'b0;
    end else begin
      if (ready_out && valid_in && !calculating) begin
        // 捕获输入数据
        data_word_reg <= data_word;
        byte_enable_reg <= byte_enable;
        calculating <= 1'b1;
        valid_out <= 1'b0;
      end
      
      if (calculating) begin
        // 计算奇偶校验
        parity_out <= parity_result;
        calculating <= 1'b0;
        valid_out <= 1'b1;
      end
      
      if (valid_out && ready_in) begin
        // 数据已被接收
        valid_out <= 1'b0;
      end
    end
  end
  
  // 优化后的奇偶校验计算
  wire [3:0] byte_parity;
  wire [7:0] byte0, byte1, byte2, byte3;
  
  // 提取字节
  assign byte0 = data_word_reg[7:0];
  assign byte1 = data_word_reg[15:8];
  assign byte2 = data_word_reg[23:16];
  assign byte3 = data_word_reg[31:24];
  
  // 并行计算每个字节的奇偶校验
  assign byte_parity[0] = byte_enable_reg[0] ? (^byte0) : 1'b0;
  assign byte_parity[1] = byte_enable_reg[1] ? (^byte1) : 1'b0;
  assign byte_parity[2] = byte_enable_reg[2] ? (^byte2) : 1'b0;
  assign byte_parity[3] = byte_enable_reg[3] ? (^byte3) : 1'b0;
  
  // 使用树形结构合并奇偶校验结果
  wire [1:0] parity_pair0, parity_pair1;
  assign parity_pair0 = byte_parity[1:0];
  assign parity_pair1 = byte_parity[3:2];
  
  wire parity_result;
  assign parity_result = (^parity_pair0) ^ (^parity_pair1);
  
  // Ready信号生成逻辑
  assign ready_out = !calculating && (!valid_out || ready_in);
  
endmodule