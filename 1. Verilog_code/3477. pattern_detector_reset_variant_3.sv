//SystemVerilog
// 顶层模块
module pattern_detector_reset #(
  parameter PATTERN = 8'b10101010
)(
  input  wire clk,
  input  wire rst,
  input  wire data_in,
  output wire pattern_detected
);
  
  wire [7:0] shift_reg_data;
  wire pattern_match;
  
  // 移位寄存器子模块
  shift_register_module u_shift_register (
    .clk        (clk),
    .rst        (rst),
    .data_in    (data_in),
    .shift_data (shift_reg_data)
  );
  
  // 模式比较器子模块 - 重构为无寄存器的组合逻辑
  pattern_comparator_module #(
    .PATTERN    (PATTERN)
  ) u_pattern_comparator (
    .shift_data        (shift_reg_data),
    .pattern_match     (pattern_match)
  );
  
  // 输出寄存器移到组合逻辑之前
  output_register u_output_register (
    .clk               (clk),
    .rst               (rst),
    .pattern_match     (pattern_match),
    .pattern_detected  (pattern_detected)
  );
  
endmodule

// 移位寄存器子模块
module shift_register_module (
  input  wire       clk,
  input  wire       rst,
  input  wire       data_in,
  output reg  [7:0] shift_data
);
  
  always @(posedge clk) begin
    if (rst) begin
      shift_data <= 8'b0;
    end else begin
      shift_data <= {shift_data[6:0], data_in};
    end
  end
  
endmodule

// 模式比较器子模块 - 转换为纯组合逻辑，移除内部寄存器
module pattern_comparator_module #(
  parameter PATTERN = 8'b10101010
)(
  input  wire [7:0] shift_data,
  output wire       pattern_match
);
  
  // 纯组合逻辑比较
  assign pattern_match = (shift_data == PATTERN);
  
endmodule

// 新增输出寄存器模块 - 将后向重定时的寄存器移到此处
module output_register (
  input  wire clk,
  input  wire rst,
  input  wire pattern_match,
  output reg  pattern_detected
);

  always @(posedge clk) begin
    if (rst) begin
      pattern_detected <= 1'b0;
    end else begin
      pattern_detected <= pattern_match;
    end
  end
  
endmodule