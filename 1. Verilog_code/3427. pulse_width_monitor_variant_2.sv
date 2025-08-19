//SystemVerilog
module pulse_width_monitor #(
  parameter MIN_WIDTH = 4
) (
  input wire clk,
  input wire reset_in,
  output reg reset_valid
);
  localparam COUNT_WIDTH = $clog2(MIN_WIDTH);
  reg [COUNT_WIDTH-1:0] width_counter;
  reg reset_in_d;
  wire pulse_start;
  wire target_reached;
  
  // 检测上升沿
  assign pulse_start = reset_in && !reset_in_d;
  // 使用确切的目标比较，避免每周期计算MIN_WIDTH-1
  assign target_reached = (width_counter == (MIN_WIDTH-1));
  
  always @(posedge clk) begin
    // 寄存输入信号以检测边沿
    reset_in_d <= reset_in;
    
    // 计数器逻辑使用case语句重构
    case ({pulse_start, reset_in, target_reached})
      3'b100: begin
        // 检测到上升沿时重置计数器
        width_counter <= 'd0;
      end
      3'b010: begin
        // 仅在需要时递增计数器，避免在达到目标后继续计数
        width_counter <= width_counter + 1'b1;
      end
      default: begin
        // 保持计数器值不变
        width_counter <= width_counter;
      end
    endcase
    
    // 重置有效信号逻辑优化
    reset_valid <= reset_in && (target_reached || (width_counter > (MIN_WIDTH-1)));
  end
endmodule