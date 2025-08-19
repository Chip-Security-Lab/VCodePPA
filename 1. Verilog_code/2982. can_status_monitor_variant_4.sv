//SystemVerilog
module can_status_monitor(
  input wire clk, rst_n,
  input wire tx_active, rx_active,
  input wire error_detected, bus_off,
  input wire [7:0] tx_err_count, rx_err_count,
  output reg [2:0] node_state,
  output reg [15:0] frames_sent, frames_received,
  output reg [15:0] errors_detected
);
  localparam ERROR_ACTIVE=0, ERROR_PASSIVE=1, BUS_OFF=2;
  reg prev_tx_active, prev_rx_active, prev_error;
  
  // Han-Carlson加法器内部信号
  wire [15:0] frames_sent_next, frames_received_next, errors_detected_next;
  
  // Han-Carlson加法器实例化
  han_carlson_adder #(.WIDTH(16)) adder_frames_sent (
    .a(frames_sent),
    .b(16'd1),
    .cin(1'b0),
    .sum(frames_sent_next)
  );
  
  han_carlson_adder #(.WIDTH(16)) adder_frames_received (
    .a(frames_received),
    .b(16'd1),
    .cin(1'b0),
    .sum(frames_received_next)
  );
  
  han_carlson_adder #(.WIDTH(16)) adder_errors_detected (
    .a(errors_detected),
    .b(16'd1),
    .cin(1'b0),
    .sum(errors_detected_next)
  );
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      node_state <= ERROR_ACTIVE;
      frames_sent <= 16'd0;
      frames_received <= 16'd0;
      errors_detected <= 16'd0;
      prev_tx_active <= 1'b0;
      prev_rx_active <= 1'b0;
      prev_error <= 1'b0;
    end else begin
      prev_tx_active <= tx_active;
      prev_rx_active <= rx_active;
      prev_error <= error_detected;
      
      // 事务计数逻辑 - 使用Han-Carlson加法器
      case({prev_tx_active, tx_active})
        2'b01: frames_sent <= frames_sent_next;
        default: frames_sent <= frames_sent;
      endcase
      
      case({prev_rx_active, rx_active})
        2'b01: frames_received <= frames_received_next;
        default: frames_received <= frames_received;
      endcase
      
      case({prev_error, error_detected})
        2'b01: errors_detected <= errors_detected_next;
        default: errors_detected <= errors_detected;
      endcase
      
      // 状态转换逻辑
      case({bus_off, (tx_err_count > 8'd127 || rx_err_count > 8'd127)})
        2'b10, 2'b11: node_state <= BUS_OFF;           // bus_off优先
        2'b01:        node_state <= ERROR_PASSIVE;     // 错误计数超标
        2'b00:        node_state <= ERROR_ACTIVE;      // 正常状态
        default:      node_state <= node_state;        // 防止锁存器
      endcase
    end
  end
endmodule

// Han-Carlson并行前缀加法器模块
module han_carlson_adder #(
  parameter WIDTH = 16
)(
  input wire [WIDTH-1:0] a,
  input wire [WIDTH-1:0] b,
  input wire cin,
  output wire [WIDTH-1:0] sum
);
  // 前缀运算所需的信号
  wire [WIDTH-1:0] p, g;
  wire [WIDTH-1:0] p_stage[0:$clog2(WIDTH)];
  wire [WIDTH-1:0] g_stage[0:$clog2(WIDTH)];
  wire [WIDTH:0] carry;
  
  // 生成初始的propagate和generate信号
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin: init_pg
      assign p[i] = a[i] ^ b[i];
      assign g[i] = a[i] & b[i];
      assign p_stage[0][i] = p[i];
      assign g_stage[0][i] = g[i];
    end
  endgenerate
  
  // Han-Carlson前缀计算
  // 只处理偶数位，奇数位延迟一阶段
  generate
    genvar stage, j;
    for (stage = 0; stage < $clog2(WIDTH)-1; stage = stage + 1) begin: hc_stages
      for (j = 0; j < WIDTH; j = j + 1) begin: hc_ops
        if (j % 2 == 0 && j + (1 << stage) < WIDTH) begin
          // 偶数位执行前缀运算
          assign g_stage[stage+1][j] = g_stage[stage][j] | (p_stage[stage][j] & g_stage[stage][j+(1<<stage)]);
          assign p_stage[stage+1][j] = p_stage[stage][j] & p_stage[stage][j+(1<<stage)];
        end else begin
          // 奇数位保持不变
          assign g_stage[stage+1][j] = g_stage[stage][j];
          assign p_stage[stage+1][j] = p_stage[stage][j];
        end
      end
    end
    
    // 最后一个阶段，处理奇数位
    for (j = 1; j < WIDTH; j = j + 2) begin: hc_final
      assign g_stage[$clog2(WIDTH)][j] = g_stage[$clog2(WIDTH)-1][j] | 
                                        (p_stage[$clog2(WIDTH)-1][j] & g_stage[$clog2(WIDTH)-1][j-1]);
      assign p_stage[$clog2(WIDTH)][j] = p_stage[$clog2(WIDTH)-1][j] & p_stage[$clog2(WIDTH)-1][j-1];
    end
    
    for (j = 0; j < WIDTH; j = j + 2) begin: hc_final_even
      assign g_stage[$clog2(WIDTH)][j] = g_stage[$clog2(WIDTH)-1][j];
      assign p_stage[$clog2(WIDTH)][j] = p_stage[$clog2(WIDTH)-1][j];
    end
  endgenerate
  
  // 计算进位
  assign carry[0] = cin;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin: carry_calc
      assign carry[i+1] = g_stage[$clog2(WIDTH)][i] | (p_stage[$clog2(WIDTH)][i] & carry[i]);
    end
  endgenerate
  
  // 计算最终和
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin: sum_calc
      assign sum[i] = p[i] ^ carry[i];
    end
  endgenerate
endmodule