//SystemVerilog
module reset_counter_alarm #(
  parameter ALARM_THRESHOLD = 4
) (
  input wire clk,
  input wire reset_in,
  input wire clear_counter,
  output reg alarm,
  output reg [3:0] reset_count
);
  reg reset_prev;
  reg signed [3:0] counter_mul_a;
  reg signed [3:0] counter_mul_b;
  wire signed [7:0] counter_product;
  reg [2:0] control_bits;
  
  // 使用带符号乘法优化实现计数功能
  assign counter_product = counter_mul_a * counter_mul_b;
  
  // 组合逻辑确定控制位和乘法操作数
  always @(*) begin
    control_bits = {clear_counter, reset_in, reset_prev};
    
    // 初始化乘法操作数
    counter_mul_a = 4'b0001;  // 基础增量值
    counter_mul_b = 4'b0001;  // 默认乘数
    
    case (control_bits)
      3'b100, 3'b101, 3'b110, 3'b111: begin
        // clear_counter为高时，使用乘法运算得到0
        counter_mul_a = 4'b0000;
        counter_mul_b = 4'b0000;
      end
      3'b010: begin
        // 上升沿检测时，通过乘法计算新值
        counter_mul_a = 4'b0001;  // 增量值
        counter_mul_b = (reset_count < 4'hF) ? 4'b0001 : 4'b0000;  // 未溢出时为1，否则为0
      end
      default: begin
        // 保持当前值的情况，通过乘法实现
        counter_mul_a = 4'b0000;
        counter_mul_b = 4'b0000;
      end
    endcase
  end
  
  // 时序逻辑更新寄存器
  always @(posedge clk) begin
    reset_prev <= reset_in;
    
    // 根据控制状态更新计数器
    case (control_bits)
      3'b100, 3'b101, 3'b110, 3'b111:
        reset_count <= 4'd0;
      3'b010:
        reset_count <= (reset_count < 4'hF) ? reset_count + counter_product[3:0] : reset_count;
      default:
        reset_count <= reset_count;
    endcase
    
    // 更新报警信号
    alarm <= (reset_count >= ALARM_THRESHOLD) || 
             ((reset_count + (control_bits == 3'b010 ? counter_product[3:0] : 4'd0)) >= ALARM_THRESHOLD);
  end
endmodule