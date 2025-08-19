//SystemVerilog
module sync_reset_monitor (
  input  wire clk,
  input  wire reset_n,
  output wire reset_stable
);
  // 内部连接信号
  wire reset_n_reg;
  wire [1:0] reset_shift;
  
  // 输入寄存器模块实例化
  input_register input_reg_inst (
    .clk         (clk),
    .reset_n     (reset_n),
    .reset_n_reg (reset_n_reg)
  );
  
  // 位移寄存器模块实例化
  shift_register shift_reg_inst (
    .clk         (clk),
    .reset_n_reg (reset_n_reg),
    .reset_shift (reset_shift)
  );
  
  // 稳定检测模块实例化
  stability_detector stability_det_inst (
    .clk          (clk),
    .reset_n_reg  (reset_n_reg),
    .reset_shift  (reset_shift),
    .reset_stable (reset_stable)
  );
  
endmodule

// 输入寄存器模块
module input_register (
  input  wire clk,
  input  wire reset_n,
  output reg  reset_n_reg
);
  
  // 使用非阻塞赋值，避免竞争条件
  always @(posedge clk) begin
    reset_n_reg <= reset_n;
  end
  
endmodule

// 位移寄存器模块
module shift_register (
  input  wire clk,
  input  wire reset_n_reg,
  output reg [1:0] reset_shift
);
  
  // 展开位移赋值，减少关键路径深度
  always @(posedge clk) begin
    reset_shift[0] <= reset_n_reg;
    reset_shift[1] <= reset_shift[0];
  end
  
endmodule

// 稳定性检测模块
module stability_detector (
  input  wire clk,
  input  wire reset_n_reg,
  input  wire [1:0] reset_shift,
  output reg  reset_stable
);
  
  // 预计算组合逻辑信号，减少关键路径
  reg reset_valid;
  
  always @(posedge clk) begin
    // 分解&操作，减少单一操作的输入数量
    reset_valid <= reset_shift[0] & reset_shift[1];
    reset_stable <= reset_valid & reset_n_reg;
  end
  
endmodule