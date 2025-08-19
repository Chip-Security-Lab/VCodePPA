//SystemVerilog
module gray_counter_reset #(parameter WIDTH = 4)(
  input clk, rst, enable,
  output reg [WIDTH-1:0] gray_count
);
  reg [WIDTH-1:0] binary_count;
  wire [WIDTH-1:0] next_binary;
  wire [WIDTH-1:0] next_gray;
  
  // 计算下一个二进制值和对应的Gray码值
  assign next_binary = binary_count + 1'b1;
  assign next_gray = next_binary ^ (next_binary >> 1);
  
  always @(posedge clk) begin
    if (rst) begin
      // 复位条件处理 - 优先级最高
      binary_count <= {WIDTH{1'b0}};
      gray_count <= {WIDTH{1'b0}};
    end
    else if (enable) begin
      // 使能条件处理
      binary_count <= next_binary;
      gray_count <= next_gray;
    end
    // 无需显式处理保持状态的情况，非阻塞赋值已保证寄存器值保持不变
  end
endmodule