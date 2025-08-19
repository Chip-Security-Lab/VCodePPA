//SystemVerilog
module uart_status_flags #(parameter DATA_W = 8) (
  input wire clk, rst_n,
  input wire rx_in, tx_start,
  input wire [DATA_W-1:0] tx_data,
  output wire tx_out,
  output wire [DATA_W-1:0] rx_data,
  output wire rx_idle, tx_idle, rx_error, rx_ready, 
  output wire tx_done,
  output wire [3:0] status_flags // [fifo_full, fifo_empty, overrun, break]
);

  // 内部信号声明 - 将寄存器和组合逻辑信号明确分开
  // 寄存器信号
  reg break_detected_r, overrun_error_r;
  reg fifo_full_r, fifo_empty_r;
  reg rx_active_r, tx_active_r;
  reg [7:0] rx_shift_r, tx_shift_r;
  reg [3:0] rx_count_r, tx_count_r;
  reg tx_out_r, tx_done_r;
  
  // 组合逻辑信号
  wire rx_active_next, tx_active_next;
  wire [3:0] rx_count_next, tx_count_next;
  wire [7:0] rx_shift_next, tx_shift_next;
  wire break_detected_next, overrun_error_next;
  wire tx_out_next, tx_done_next;
  
  // 组合逻辑输出映射
  assign rx_idle = !rx_active_r;
  assign tx_idle = !tx_active_r;
  assign rx_error = overrun_error_r || break_detected_r;
  assign status_flags = {fifo_full_r, fifo_empty_r, overrun_error_r, break_detected_r};
  assign rx_data = rx_shift_r;
  assign rx_ready = (rx_count_r == 4'd10);
  assign tx_done = tx_done_r;
  assign tx_out = tx_out_r;

  // 接收器组合逻辑
  rx_combinational rx_comb (
    .rx_in(rx_in),
    .rx_active(rx_active_r),
    .rx_count(rx_count_r),
    .rx_shift(rx_shift_r),
    .break_detected(break_detected_r),
    .overrun_error(overrun_error_r),
    .rx_ready(rx_ready),
    .rx_active_next(rx_active_next),
    .rx_count_next(rx_count_next),
    .rx_shift_next(rx_shift_next),
    .break_detected_next(break_detected_next),
    .overrun_error_next(overrun_error_next)
  );

  // 发送器组合逻辑
  tx_combinational tx_comb (
    .tx_start(tx_start),
    .tx_active(tx_active_r),
    .tx_count(tx_count_r),
    .tx_shift(tx_shift_r),
    .tx_data(tx_data),
    .tx_active_next(tx_active_next),
    .tx_count_next(tx_count_next),
    .tx_shift_next(tx_shift_next),
    .tx_out_next(tx_out_next),
    .tx_done_next(tx_done_next)
  );

  // 时序逻辑 - 所有寄存器在一个时序块中更新
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 重置所有寄存器到初始状态
      rx_active_r <= 1'b0;
      rx_count_r <= 4'b0;
      rx_shift_r <= 8'b0;
      break_detected_r <= 1'b0;
      overrun_error_r <= 1'b0;
      tx_active_r <= 1'b0;
      tx_count_r <= 4'b0;
      tx_shift_r <= 8'b0;
      tx_out_r <= 1'b1;
      tx_done_r <= 1'b0;
      fifo_full_r <= 1'b0;
      fifo_empty_r <= 1'b1;
    end else begin
      // 更新所有寄存器
      rx_active_r <= rx_active_next;
      rx_count_r <= rx_count_next;
      rx_shift_r <= rx_shift_next;
      break_detected_r <= break_detected_next;
      overrun_error_r <= overrun_error_next;
      tx_active_r <= tx_active_next;
      tx_count_r <= tx_count_next;
      tx_shift_r <= tx_shift_next;
      tx_out_r <= tx_out_next;
      tx_done_r <= tx_done_next;
    end
  end
endmodule

// 接收器组合逻辑模块
module rx_combinational (
  input wire rx_in,
  input wire rx_active,
  input wire [3:0] rx_count,
  input wire [7:0] rx_shift,
  input wire break_detected,
  input wire overrun_error,
  input wire rx_ready,
  output wire rx_active_next,
  output wire [3:0] rx_count_next,
  output wire [7:0] rx_shift_next,
  output wire break_detected_next,
  output wire overrun_error_next
);
  
  // 组合逻辑计算
  assign rx_active_next = (!rx_active && rx_in == 1'b0) ? 1'b1 :
                          (rx_active && rx_count == 4'd9) ? 1'b0 : rx_active;
  
  wire [3:0] rx_count_plus_one;
  
  // 使用Kogge-Stone加法器实现rx_count + 1
  kogge_stone_adder #(
    .WIDTH(4)
  ) rx_counter_adder (
    .a(rx_count),
    .b(4'd1),
    .cin(1'b0),
    .sum(rx_count_plus_one),
    .cout()
  );
  
  assign rx_count_next = (!rx_active && rx_in == 1'b0) ? 4'd0 :
                         (rx_active && rx_count < 4'd9) ? rx_count_plus_one :
                         (rx_active && rx_count == 4'd9) ? 4'd10 : rx_count;
  
  assign rx_shift_next = (rx_active && rx_count < 4'd9) ? {rx_in, rx_shift[7:1]} : rx_shift;
  
  assign break_detected_next = break_detected || 
                              (rx_active && rx_count == 4'd9 && rx_in == 1'b0);
  
  assign overrun_error_next = (rx_active && rx_count == 4'd9 && rx_ready) ? 1'b1 : overrun_error;
  
endmodule

// 发送器组合逻辑模块
module tx_combinational (
  input wire tx_start,
  input wire tx_active,
  input wire [3:0] tx_count,
  input wire [7:0] tx_shift,
  input wire [7:0] tx_data,
  output wire tx_active_next,
  output wire [3:0] tx_count_next,
  output wire [7:0] tx_shift_next,
  output wire tx_out_next,
  output wire tx_done_next
);
  
  // 组合逻辑计算
  assign tx_active_next = (!tx_active && tx_start) ? 1'b1 :
                          (tx_active && tx_count == 4'd9) ? 1'b0 : tx_active;
  
  wire [3:0] tx_count_plus_one;
  
  // 使用Kogge-Stone加法器实现tx_count + 1
  kogge_stone_adder #(
    .WIDTH(4)
  ) tx_counter_adder (
    .a(tx_count),
    .b(4'd1),
    .cin(1'b0),
    .sum(tx_count_plus_one),
    .cout()
  );
  
  assign tx_count_next = (!tx_active && tx_start) ? 4'd0 :
                         (tx_active && tx_count < 4'd9) ? tx_count_plus_one : tx_count;
  
  assign tx_shift_next = (!tx_active && tx_start) ? tx_data :
                         (tx_active && tx_count < 4'd8) ? {1'b0, tx_shift[7:1]} : tx_shift;
  
  assign tx_out_next = (!tx_active && tx_start) ? 1'b0 :
                      (tx_active && tx_count < 4'd8) ? tx_shift[0] :
                      (tx_active && tx_count >= 4'd8) ? 1'b1 : 1'b1;
  
  assign tx_done_next = (tx_active && tx_count == 4'd9) ? 1'b1 : 
                        (!tx_active && tx_start) ? 1'b0 : tx_done_next;
  
endmodule

// Kogge-Stone并行前缀加法器
module kogge_stone_adder #(
  parameter WIDTH = 8
)(
  input wire [WIDTH-1:0] a,
  input wire [WIDTH-1:0] b,
  input wire cin,
  output wire [WIDTH-1:0] sum,
  output wire cout
);
  
  // 生成(G)和传播(P)信号
  wire [WIDTH-1:0] G, P;
  wire [WIDTH-1:0] G_prev, P_prev;
  
  // 第一级 - 生成基础G和P信号
  assign G = a & b;             // 生成信号
  assign P = a ^ b;             // 传播信号
  
  // 定义内部变量存储各级结果
  wire [WIDTH-1:0] G_temp[0:$clog2(WIDTH)-1]; 
  wire [WIDTH-1:0] P_temp[0:$clog2(WIDTH)-1];
  
  // 第一级赋值
  assign G_temp[0] = G;
  assign P_temp[0] = P;
  
  // 并行前缀树计算进位
  genvar i, j;
  generate
    for (i = 1; i <= $clog2(WIDTH); i = i + 1) begin: prefix_tree_level
      for (j = 0; j < WIDTH; j = j + 1) begin: bit_level
        if (j >= (1<<(i-1))) begin
          // 前缀计算规则: G_i:j = G_i:k + P_i:k * G_k-1:j
          // 其中k = i - 2^(level-1)
          assign G_temp[i][j] = G_temp[i-1][j] | (P_temp[i-1][j] & G_temp[i-1][j-(1<<(i-1))]);
          assign P_temp[i][j] = P_temp[i-1][j] & P_temp[i-1][j-(1<<(i-1))];
        end else begin
          // 对于不需要合并的位置，直接传递
          assign G_temp[i][j] = G_temp[i-1][j];
          assign P_temp[i][j] = P_temp[i-1][j];
        end
      end
    end
  endgenerate
  
  // 计算最终进位信号
  wire [WIDTH:0] carries;
  assign carries[0] = cin;
  
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin: carry_generation
      if (i == 0) begin
        assign carries[i+1] = G_temp[$clog2(WIDTH)-1][i] | (P_temp[$clog2(WIDTH)-1][i] & cin);
      end else begin
        assign carries[i+1] = G_temp[$clog2(WIDTH)-1][i];
      end
    end
  endgenerate
  
  // 计算求和结果
  assign sum = P ^ carries[WIDTH-1:0];
  assign cout = carries[WIDTH];
  
endmodule