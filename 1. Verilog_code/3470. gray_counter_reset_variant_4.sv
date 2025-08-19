//SystemVerilog
module gray_counter_reset #(parameter WIDTH = 4)(
  input clk, rst, enable,
  output reg [WIDTH-1:0] gray_count
);
  reg [WIDTH-1:0] binary_count;
  wire [WIDTH-1:0] next_binary_count;
  wire [WIDTH-1:0] shifted_binary;
  wire [WIDTH-1:0] next_gray_count;
  
  // 使用加法器计算下一个二进制值
  assign next_binary_count = binary_count + 1'b1;
  
  // 使用桶形移位器实现右移1位
  // 桶形移位器结构
  generate
    // 最高位补0
    assign shifted_binary[WIDTH-1] = 1'b0;
    // 其余位使用上一位的值
    genvar i;
    for (i = 0; i < WIDTH-1; i = i + 1) begin : barrel_shifter
      assign shifted_binary[i] = binary_count[i+1];
    end
  endgenerate
  
  // 计算灰码
  assign next_gray_count = next_binary_count ^ shifted_binary;
  
  // 寄存器更新逻辑
  always @(posedge clk) begin
    if (rst) begin
      binary_count <= {WIDTH{1'b0}};
      gray_count <= {WIDTH{1'b0}};
    end else if (enable) begin
      binary_count <= next_binary_count;
      gray_count <= next_gray_count;
    end
  end
endmodule