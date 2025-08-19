//SystemVerilog
module matrix_parity_gen(
  input wire clk,
  input wire rst_n,
  input wire [15:0] data_matrix,
  output reg [3:0] row_parity,
  output reg [3:0] col_parity
);

  // 中间寄存器，用于切分数据路径
  reg [15:0] data_matrix_reg;
  
  // 行奇偶校验中间结果
  wire [3:0] row_parity_stage1;
  
  // 列奇偶校验中间结果
  wire [3:0] col_parity_stage1;
  
  // 数据输入寄存器阶段
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_matrix_reg <= 16'b0;
    end else begin
      data_matrix_reg <= data_matrix;
    end
  end
  
  // 第一级流水线：计算行和列奇偶校验
  // 行奇偶校验计算 - 使用异或运算符简化表达
  assign row_parity_stage1[0] = ^data_matrix_reg[3:0];
  assign row_parity_stage1[1] = ^data_matrix_reg[7:4];
  assign row_parity_stage1[2] = ^data_matrix_reg[11:8];
  assign row_parity_stage1[3] = ^data_matrix_reg[15:12];
  
  // 列奇偶校验计算 - 重构为更清晰的模式
  assign col_parity_stage1[0] = data_matrix_reg[0] ^ data_matrix_reg[4] ^ 
                               data_matrix_reg[8] ^ data_matrix_reg[12];
  assign col_parity_stage1[1] = data_matrix_reg[1] ^ data_matrix_reg[5] ^ 
                               data_matrix_reg[9] ^ data_matrix_reg[13];
  assign col_parity_stage1[2] = data_matrix_reg[2] ^ data_matrix_reg[6] ^ 
                               data_matrix_reg[10] ^ data_matrix_reg[14];
  assign col_parity_stage1[3] = data_matrix_reg[3] ^ data_matrix_reg[7] ^ 
                               data_matrix_reg[11] ^ data_matrix_reg[15];
  
  // 第二级流水线：输出寄存器阶段
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      row_parity <= 4'b0;
      col_parity <= 4'b0;
    end else begin
      row_parity <= row_parity_stage1;
      col_parity <= col_parity_stage1;
    end
  end

endmodule