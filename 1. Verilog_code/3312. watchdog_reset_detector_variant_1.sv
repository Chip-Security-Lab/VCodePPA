//SystemVerilog
module watchdog_reset_detector #(parameter TIMEOUT = 16'hFFFF)(
  input clk,
  input enable,
  input watchdog_kick,
  input ext_reset_n,
  input pwr_reset_n,
  output reg system_reset,
  output reg [1:0] reset_source
);

  reg [15:0] watchdog_counter = 16'h0000;

  // 一级缓冲寄存器用于高扇出信号
  reg ext_reset_buf1, ext_reset_buf2;
  reg pwr_reset_buf1, pwr_reset_buf2;
  reg watchdog_timeout_buf1, watchdog_timeout_buf2;

  wire ext_reset_int = ~ext_reset_n;
  wire pwr_reset_int = ~pwr_reset_n;
  wire watchdog_timeout_int = (watchdog_counter >= TIMEOUT);

  // CLA信号定义
  wire [15:0] cla_sum;
  wire cla_carry_out;
  reg  [15:0] adder_in_a;
  reg  [15:0] adder_in_b;
  reg         adder_cin;

  // 多级缓冲寄存器，分散高扇出
  always @(posedge clk) begin
    ext_reset_buf1 <= ext_reset_int;
    ext_reset_buf2 <= ext_reset_buf1;

    pwr_reset_buf1 <= pwr_reset_int;
    pwr_reset_buf2 <= pwr_reset_buf1;

    watchdog_timeout_buf1 <= watchdog_timeout_int;
    watchdog_timeout_buf2 <= watchdog_timeout_buf1;
  end

  // CLA输入选择
  always @(*) begin
    if (!enable)
    begin
      adder_in_a = 16'h0000;
      adder_in_b = 16'h0000;
      adder_cin  = 1'b0;
    end
    else if (watchdog_kick)
    begin
      adder_in_a = 16'h0000;
      adder_in_b = 16'h0000;
      adder_cin  = 1'b0;
    end
    else
    begin
      adder_in_a = watchdog_counter;
      adder_in_b = 16'h0001;
      adder_cin  = 1'b0;
    end
  end

  // 带状进位加法器实例
  cla16 u_cla16 (
    .a(adder_in_a),
    .b(adder_in_b),
    .cin(adder_cin),
    .sum(cla_sum),
    .cout(cla_carry_out)
  );

  always @(posedge clk) begin
    if (!enable)
      watchdog_counter <= 16'h0000;
    else if (watchdog_kick)
      watchdog_counter <= 16'h0000;
    else
      watchdog_counter <= cla_sum;

    system_reset <= watchdog_timeout_buf2 | ext_reset_buf2 | pwr_reset_buf2;

    if (pwr_reset_buf2)
      reset_source <= 2'b00;
    else if (ext_reset_buf2)
      reset_source <= 2'b01;
    else if (watchdog_timeout_buf2)
      reset_source <= 2'b10;
    else
      reset_source <= 2'b11;
  end

endmodule

module cla16 (
  input  [15:0] a,
  input  [15:0] b,
  input         cin,
  output [15:0] sum,
  output        cout
);
  wire [15:0] p, g;
  wire [16:0] c;

  assign p = a ^ b;
  assign g = a & b;

  assign c[0] = cin;
  assign c[1]  = g[0]  | (p[0]  & c[0]);
  assign c[2]  = g[1]  | (p[1]  & c[1]);
  assign c[3]  = g[2]  | (p[2]  & c[2]);
  assign c[4]  = g[3]  | (p[3]  & c[3]);
  assign c[5]  = g[4]  | (p[4]  & c[4]);
  assign c[6]  = g[5]  | (p[5]  & c[5]);
  assign c[7]  = g[6]  | (p[6]  & c[6]);
  assign c[8]  = g[7]  | (p[7]  & c[7]);
  assign c[9]  = g[8]  | (p[8]  & c[8]);
  assign c[10] = g[9]  | (p[9]  & c[9]);
  assign c[11] = g[10] | (p[10] & c[10]);
  assign c[12] = g[11] | (p[11] & c[11]);
  assign c[13] = g[12] | (p[12] & c[12]);
  assign c[14] = g[13] | (p[13] & c[13]);
  assign c[15] = g[14] | (p[14] & c[14]);
  assign c[16] = g[15] | (p[15] & c[15]);

  assign sum = p ^ c[15:0];
  assign cout = c[16];

endmodule