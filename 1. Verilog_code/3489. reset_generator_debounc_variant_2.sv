//SystemVerilog
module reset_generator_debounce #(
  parameter DEBOUNCE_LEN = 4
)(
  input  wire clk,
  input  wire button_in,
  output reg  reset_out
);
  
  reg [DEBOUNCE_LEN-1:0] debounce_reg;
  
  // 优化比较逻辑的实现
  wire compare_upper_ones, compare_lower_ones;
  wire compare_upper_zeros, compare_lower_zeros;
  reg detect_ones, detect_zeros;
  wire [1:0] debounce_state;
  
  // 分解比较操作为更小的并行块，减少关键路径
  assign compare_upper_ones = &debounce_reg[DEBOUNCE_LEN-1:DEBOUNCE_LEN/2];
  assign compare_lower_ones = &debounce_reg[DEBOUNCE_LEN/2-1:0];
  assign compare_upper_zeros = ~|debounce_reg[DEBOUNCE_LEN-1:DEBOUNCE_LEN/2];
  assign compare_lower_zeros = ~|debounce_reg[DEBOUNCE_LEN/2-1:0];
  
  // 将检测逻辑分离到单独的寄存器，更好的利用时序逻辑
  always @(posedge clk) begin
    detect_ones <= compare_upper_ones & compare_lower_ones;
    detect_zeros <= compare_upper_zeros & compare_lower_zeros;
  end
  
  // 状态检测逻辑
  assign debounce_state = {detect_ones, detect_zeros};
  
  // 主状态更新逻辑
  always @(posedge clk) begin
    // 高效的移位寄存器实现
    debounce_reg <= {debounce_reg[DEBOUNCE_LEN-2:0], button_in};
    
    // 使用优化的case语句实现
    case (debounce_state)
      2'b10:   reset_out <= 1'b1;   // 检测到所有位都是1
      2'b01:   reset_out <= 1'b0;   // 检测到所有位都是0
      default: reset_out <= reset_out; // 保持当前状态
    endcase
  end
  
endmodule