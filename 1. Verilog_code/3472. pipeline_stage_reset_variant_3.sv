//SystemVerilog
module pipeline_stage_reset #(parameter WIDTH = 32)(
  input clk, rst,
  input [WIDTH-1:0] data_in,
  input valid_in,
  output reg [WIDTH-1:0] data_out,
  output reg valid_out
);
  // 内部信号声明
  reg [7:0] minuend, subtrahend;
  wire [7:0] difference_comb;
  wire borrow_comb;
  
  // 实例化组合逻辑模块
  subtractor_8bit subtractor_inst (
    .minuend(minuend),
    .subtrahend(subtrahend),
    .difference(difference_comb),
    .borrow(borrow_comb)
  );
  
  // 时序逻辑部分
  always @(posedge clk) begin
    if (rst) begin
      data_out <= {WIDTH{1'b0}};
      valid_out <= 1'b0;
      minuend <= 8'b0;
      subtrahend <= 8'b0;
    end else begin
      // 基本数据传递
      data_out <= data_in;
      valid_out <= valid_in;
      
      // 从输入数据中提取减法操作数
      if (valid_in) begin
        minuend <= data_in[7:0];
        subtrahend <= data_in[15:8];
        // 将减法结果放回data_out的相应位置
        data_out[23:16] <= difference_comb;
      end
    end
  end
endmodule

// 纯组合逻辑模块 - 8位减法器
module subtractor_8bit (
  input [7:0] minuend,
  input [7:0] subtrahend,
  output [7:0] difference,
  output borrow
);
  // 内部信号
  reg [7:0] diff_temp;
  reg borrow_temp;
  wire [8:0] result;
  
  // 组合逻辑实现
  always @(*) begin
    {borrow_temp, diff_temp} = 9'b0;
    for (integer i = 0; i < 8; i = i + 1) begin
      diff_temp[i] = minuend[i] ^ subtrahend[i] ^ borrow_temp;
      borrow_temp = (~minuend[i] & subtrahend[i]) | 
                   (~minuend[i] & borrow_temp) | 
                   (subtrahend[i] & borrow_temp);
    end
  end
  
  // 输出赋值
  assign difference = diff_temp;
  assign borrow = borrow_temp;
endmodule