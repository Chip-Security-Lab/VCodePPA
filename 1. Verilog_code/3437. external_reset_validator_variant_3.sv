//SystemVerilog
module external_reset_validator (
  input  wire clk,
  input  wire ext_reset,
  input  wire validation_en,
  output wire valid_reset,
  output wire invalid_reset
);
  
  // 内部信号
  wire reset_detected;
  
  // 实例化子模块
  reset_synchronizer u_reset_sync (
    .clk           (clk),
    .ext_reset     (ext_reset),
    .reset_detected(reset_detected)
  );
  
  reset_validator u_reset_validator (
    .clk           (clk),
    .reset_detected(reset_detected),
    .validation_en (validation_en),
    .valid_reset   (valid_reset),
    .invalid_reset (invalid_reset)
  );
  
endmodule

// 双寄存器同步器子模块
module reset_synchronizer (
  input  wire clk,
  input  wire ext_reset,
  output wire reset_detected
);
  
  // 使用两级寄存器实现同步
  reg [1:0] ext_reset_sync;
  
  always @(posedge clk) begin
    ext_reset_sync <= {ext_reset_sync[0], ext_reset};
  end
  
  // 输出同步后的复位信号
  assign reset_detected = ext_reset_sync[1];
  
endmodule

// 复位验证子模块
module reset_validator (
  input  wire clk,
  input  wire reset_detected,
  input  wire validation_en,
  output reg  valid_reset,
  output reg  invalid_reset
);
  
  // 基于同步后的复位信号和验证使能，生成有效/无效复位信号
  always @(posedge clk) begin
    valid_reset   <= reset_detected & validation_en;
    invalid_reset <= reset_detected & ~validation_en;
  end
  
endmodule