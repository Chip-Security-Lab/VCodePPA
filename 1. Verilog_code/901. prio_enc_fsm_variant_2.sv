//SystemVerilog
// SystemVerilog
// IEEE 1364-2005 Verilog标准
module prio_enc_fsm #(parameter WIDTH=6)(
  input clk, rst,
  input [WIDTH-1:0] in,
  output reg [$clog2(WIDTH)-1:0] addr
);
  // 使用参数化的位宽
  localparam ADDR_WIDTH = $clog2(WIDTH);
  
  // 状态编码
  localparam IDLE = 1'b0;
  localparam SCAN = 1'b1;
  
  reg state;
  reg [WIDTH-1:0] in_r; // 寄存输入以提高时序性能
  
  // 中间信号定义
  reg has_ones;
  reg [ADDR_WIDTH-1:0] first_one_pos;
  
  // 优化的优先编码器逻辑
  function [ADDR_WIDTH-1:0] find_first_one;
    input [WIDTH-1:0] vector;
    integer j;
    reg found;
    begin
      found = 1'b0;
      find_first_one = {ADDR_WIDTH{1'b0}}; // 默认值
      for (j = WIDTH-1; j >= 0; j = j - 1) begin
        if (vector[j] && !found) begin
          find_first_one = j[ADDR_WIDTH-1:0];
          found = 1'b1;
        end
      end
    end
  endfunction
  
  // 检测输入是否有1
  always @(*) begin
    has_ones = |in;
  end
  
  // 计算第一个1的位置
  always @(*) begin
    first_one_pos = find_first_one(in_r);
  end
  
  // 主状态机
  always @(posedge clk) begin
    if (rst) begin
      state <= IDLE;
      addr <= {ADDR_WIDTH{1'b0}};
      in_r <= {WIDTH{1'b0}};
    end 
    else begin
      case (state)
        IDLE: begin
          // 总是在IDLE状态寄存输入
          in_r <= in;
          
          // 状态转换逻辑
          if (has_ones) begin
            state <= SCAN;
          end
          else begin
            state <= IDLE;
          end
        end
        
        SCAN: begin
          // 使用预先计算的结果
          addr <= first_one_pos;
          state <= IDLE;
        end
        
        default: begin
          state <= IDLE;
        end
      endcase
    end
  end
endmodule