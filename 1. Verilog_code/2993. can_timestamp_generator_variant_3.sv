//SystemVerilog
module can_timestamp_generator(
  input wire clk, rst_n,
  input wire can_rx_edge, can_frame_start, can_frame_end,
  output reg [31:0] current_timestamp,
  output reg [31:0] frame_timestamp,
  output reg timestamp_valid
);
  reg [15:0] prescaler_count;
  localparam PRESCALER = 1000; // For microsecond resolution
  
  wire [31:0] next_timestamp;
  
  // 实例化先行进位加法器
  carry_lookahead_adder cla_inst (
    .a(current_timestamp),
    .b(32'h00000001),
    .cin(1'b0),
    .sum(next_timestamp),
    .cout()
  );
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_timestamp <= 0;
      frame_timestamp <= 0;
      timestamp_valid <= 0;
      prescaler_count <= 0;
    end else begin
      timestamp_valid <= 0;
      
      prescaler_count <= prescaler_count + 1;
      if (prescaler_count >= PRESCALER - 1) begin
        prescaler_count <= 0;
        current_timestamp <= next_timestamp;
      end
      
      if (can_frame_start) begin
        frame_timestamp <= current_timestamp;
      end
      
      if (can_frame_end) begin
        timestamp_valid <= 1;
      end
    end
  end
endmodule

// 32位先行进位加法器
module carry_lookahead_adder(
  input [31:0] a,
  input [31:0] b,
  input cin,
  output [31:0] sum,
  output cout
);
  wire [31:0] p, g; // 传播位和生成位
  wire [32:0] c;    // 进位信号
  
  // 计算传播位和生成位
  assign p = a ^ b;
  assign g = a & b;
  
  // 初始进位
  assign c[0] = cin;
  
  // 展开的进位链生成 - 替代了原来的for循环
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & c[1]);
  assign c[3] = g[2] | (p[2] & c[2]);
  assign c[4] = g[3] | (p[3] & c[3]);
  assign c[5] = g[4] | (p[4] & c[4]);
  assign c[6] = g[5] | (p[5] & c[5]);
  assign c[7] = g[6] | (p[6] & c[6]);
  assign c[8] = g[7] | (p[7] & c[7]);
  assign c[9] = g[8] | (p[8] & c[8]);
  assign c[10] = g[9] | (p[9] & c[9]);
  assign c[11] = g[10] | (p[10] & c[10]);
  assign c[12] = g[11] | (p[11] & c[11]);
  assign c[13] = g[12] | (p[12] & c[12]);
  assign c[14] = g[13] | (p[13] & c[13]);
  assign c[15] = g[14] | (p[14] & c[14]);
  assign c[16] = g[15] | (p[15] & c[15]);
  assign c[17] = g[16] | (p[16] & c[16]);
  assign c[18] = g[17] | (p[17] & c[17]);
  assign c[19] = g[18] | (p[18] & c[18]);
  assign c[20] = g[19] | (p[19] & c[19]);
  assign c[21] = g[20] | (p[20] & c[20]);
  assign c[22] = g[21] | (p[21] & c[21]);
  assign c[23] = g[22] | (p[22] & c[22]);
  assign c[24] = g[23] | (p[23] & c[23]);
  assign c[25] = g[24] | (p[24] & c[24]);
  assign c[26] = g[25] | (p[25] & c[25]);
  assign c[27] = g[26] | (p[26] & c[26]);
  assign c[28] = g[27] | (p[27] & c[27]);
  assign c[29] = g[28] | (p[28] & c[28]);
  assign c[30] = g[29] | (p[29] & c[29]);
  assign c[31] = g[30] | (p[30] & c[30]);
  assign c[32] = g[31] | (p[31] & c[31]);
  
  // 计算和
  assign sum = p ^ c[31:0];
  
  // 输出进位
  assign cout = c[32];
endmodule