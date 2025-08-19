//SystemVerilog
module power_on_reset #(
  parameter POR_CYCLES = 32
) (
  input  wire clk,
  input  wire power_good,
  output wire system_rst_n
);
  // 内部信号定义
  wire [$clog2(POR_CYCLES)-1:0] por_counter;
  wire [7:0] lut_subtractor_a;
  wire [7:0] lut_subtractor_b;
  wire [7:0] lut_result;
  
  // 子模块实例化
  por_counter_module #(
    .POR_CYCLES(POR_CYCLES)
  ) counter_inst (
    .clk(clk),
    .power_good(power_good),
    .lut_result(lut_result),
    .por_counter(por_counter)
  );
  
  subtraction_input_module #(
    .POR_CYCLES(POR_CYCLES)
  ) sub_input_inst (
    .por_counter(por_counter),
    .lut_subtractor_a(lut_subtractor_a),
    .lut_subtractor_b(lut_subtractor_b)
  );
  
  subtraction_lut_module lut_inst (
    .clk(clk),
    .power_good(power_good),
    .lut_subtractor_a(lut_subtractor_a),
    .lut_subtractor_b(lut_subtractor_b),
    .lut_result(lut_result)
  );
  
  reset_control_module reset_inst (
    .clk(clk),
    .power_good(power_good),
    .lut_result(lut_result),
    .system_rst_n(system_rst_n)
  );
  
endmodule

// 计数器模块 - 负责管理POR计数
module por_counter_module #(
  parameter POR_CYCLES = 32
) (
  input  wire clk,
  input  wire power_good,
  input  wire [7:0] lut_result,
  output reg  [$clog2(POR_CYCLES)-1:0] por_counter
);

  always @(posedge clk or negedge power_good) begin
    if (!power_good) begin
      por_counter <= 0;
    end else if (lut_result != 0) begin
      por_counter <= por_counter + 1;
    end
  end
  
endmodule

// 减法输入准备模块 - 为LUT查找表准备输入参数
module subtraction_input_module #(
  parameter POR_CYCLES = 32
) (
  input  wire [$clog2(POR_CYCLES)-1:0] por_counter,
  output wire [7:0] lut_subtractor_a,
  output wire [7:0] lut_subtractor_b
);

  assign lut_subtractor_a = POR_CYCLES - 1;
  assign lut_subtractor_b = por_counter;
  
endmodule

// 减法查找表模块 - 实现LUT减法功能
module subtraction_lut_module (
  input  wire clk,
  input  wire power_good,
  input  wire [7:0] lut_subtractor_a,
  input  wire [7:0] lut_subtractor_b,
  output reg  [7:0] lut_result
);

  // 查找表声明
  reg [7:0] subtraction_lut [0:255][0:255];
  
  // 初始化查找表
  integer i, j;
  initial begin
    for (i = 0; i < 256; i = i + 1) begin
      for (j = 0; j < 256; j = j + 1) begin
        subtraction_lut[i][j] = i - j;
      end
    end
  end
  
  // 查找表操作
  always @(posedge clk or negedge power_good) begin
    if (!power_good) begin
      lut_result <= 0;
    end else begin
      lut_result <= subtraction_lut[lut_subtractor_a][lut_subtractor_b];
    end
  end
  
endmodule

// 复位控制模块 - 管理系统复位信号
module reset_control_module (
  input  wire clk,
  input  wire power_good,
  input  wire [7:0] lut_result,
  output reg  system_rst_n
);

  always @(posedge clk or negedge power_good) begin
    if (!power_good) begin
      system_rst_n <= 1'b0;
    end else begin
      system_rst_n <= (lut_result == 0);
    end
  end
  
endmodule