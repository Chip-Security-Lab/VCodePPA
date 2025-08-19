//SystemVerilog
module sliding_window_parity(
  input clk, rst_n,
  input data_bit,
  input [2:0] window_size,
  output reg window_parity
);
  // 数据通路第一级：移位寄存器
  reg [7:0] shift_reg;
  
  // 预计算的窗口掩码 - 提前计算以减少组合逻辑路径
  reg [7:0] window_mask;
  
  // 优化的奇偶校验结果计算
  reg odd_parity;
  
  // 移位寄存器更新
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg <= 8'h00;
    end else begin
      shift_reg <= {shift_reg[6:0], data_bit};
    end
  end
  
  // 基于窗口大小生成掩码
  always @(*) begin
    case(window_size)
      3'd1: window_mask = 8'h01;
      3'd2: window_mask = 8'h03;
      3'd3: window_mask = 8'h07;
      3'd4: window_mask = 8'h0F;
      3'd5: window_mask = 8'h1F;
      3'd6: window_mask = 8'h3F;
      3'd7: window_mask = 8'h7F;
      default: window_mask = 8'hFF; // 3'd0 或 3'd8 都使用全部8位
    endcase
  end
  
  // 使用查找表实现归约XOR - 改善时序
  function automatic reg xor_reduce;
    input [7:0] data;
    input [7:0] mask;
    reg [7:0] masked_data;
    reg result;
    begin
      masked_data = data & mask;
      
      // 使用树状结构进行XOR归约，减少关键路径
      result = ^masked_data;
      xor_reduce = result;
    end
  endfunction
  
  // 奇偶校验计算 - 优化时序路径
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      odd_parity <= 1'b0;
      window_parity <= 1'b0;
    end else begin
      // 单周期计算奇偶校验
      odd_parity <= xor_reduce(shift_reg, window_mask);
      window_parity <= odd_parity;
    end
  end
  
endmodule