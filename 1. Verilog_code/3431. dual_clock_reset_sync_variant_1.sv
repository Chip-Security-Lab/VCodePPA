//SystemVerilog
//IEEE 1364-2005 Verilog标准
// 顶层模块
module dual_clock_reset_sync (
  input  wire clk_a,
  input  wire clk_b,
  input  wire reset_in,
  input  wire ready_a,
  input  wire ready_b,
  output wire valid_a,
  output wire valid_b,
  output wire reset_a,
  output wire reset_b
);
  
  // 例化时钟域A的复位同步器
  clock_domain_reset_sync domain_a_sync (
    .clk        (clk_a),
    .reset_in   (reset_in),
    .ready      (ready_a),
    .valid      (valid_a),
    .reset_out  (reset_a)
  );
  
  // 例化时钟域B的复位同步器
  clock_domain_reset_sync domain_b_sync (
    .clk        (clk_b),
    .reset_in   (reset_in),
    .ready      (ready_b),
    .valid      (valid_b),
    .reset_out  (reset_b)
  );
  
endmodule

// 单时钟域复位同步子模块
module clock_domain_reset_sync (
  input  wire clk,       // 时钟域时钟
  input  wire reset_in,  // 异步复位输入
  input  wire ready,     // 就绪信号
  output wire valid,     // 有效信号输出
  output wire reset_out  // 同步复位输出
);
  
  reg [2:0] sync_reg;    // 三级同步器寄存器
  reg       valid_reg;   // 有效状态寄存器
  
  // 复位同步逻辑实现 - 扁平化if-else结构
  always @(posedge clk or posedge reset_in) begin
    if (reset_in) begin
      sync_reg  <= 3'b111;
      valid_reg <= 1'b0;
    end else if (ready || !valid_reg) begin
      sync_reg  <= {sync_reg[1:0], 1'b0};
      valid_reg <= 1'b1;
    end
  end
  
  // 输出赋值
  assign reset_out = sync_reg[2];  // 使用级联触发器的最后一级作为同步复位输出
  assign valid     = valid_reg;    // 有效信号直接连接
  
endmodule