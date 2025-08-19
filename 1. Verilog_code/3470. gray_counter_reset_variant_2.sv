//SystemVerilog
module gray_counter_reset #(parameter WIDTH = 8)(
  input clk, rst, enable,
  output reg [WIDTH-1:0] gray_count
);
  reg [WIDTH-1:0] binary_count;
  reg [WIDTH-1:0] next_binary;
  wire [WIDTH-1:0] ones_complement;
  wire [WIDTH-1:0] twos_complement;
  wire [WIDTH-1:0] increment_value;
  
  // 使用二进制补码减法算法实现计数器递增
  // 对于计数器+1，等价于 -((-binary_count)-1)
  assign ones_complement = ~binary_count;                  // 一的补码
  assign twos_complement = ones_complement + 1'b1;         // 二的补码
  assign increment_value = ~(twos_complement - 1'b1) + 1'b1; // 使用补码减法实现+1
  
  always @(posedge clk) begin
    case({rst, enable})
      2'b10, 2'b11: begin  // 复位优先（当rst=1时，不管enable值如何）
        binary_count <= {WIDTH{1'b0}};
        gray_count <= {WIDTH{1'b0}};
      end
      
      2'b01: begin  // 使能（当rst=0且enable=1时）
        next_binary = binary_count + increment_value;
        binary_count <= next_binary;
        gray_count <= next_binary ^ (next_binary >> 1);
      end
      
      2'b00: begin  // 保持当前值（当rst=0且enable=0时）
        binary_count <= binary_count;
        gray_count <= gray_count;
      end
      
      default: begin  // 默认情况（冗余路径，增强代码健壮性）
        binary_count <= binary_count;
        gray_count <= gray_count;
      end
    endcase
  end
endmodule