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
  
  // 跳跃进位加法器内部信号
  wire [15:0] frames_sent_next, frames_received_next, errors_detected_next;
  wire [15:0] p_frames_sent, g_frames_sent;
  wire [15:0] p_frames_received, g_frames_received;
  wire [15:0] p_errors_detected, g_errors_detected;
  wire [15:0] c_frames_sent, c_frames_received, c_errors_detected;
  
  // 生成传播和生成信号 - frames_sent
  assign p_frames_sent = frames_sent;
  assign g_frames_sent = 16'h0001; // 添加1
  
  // 生成传播和生成信号 - frames_received
  assign p_frames_received = frames_received;
  assign g_frames_received = 16'h0001; // 添加1
  
  // 生成传播和生成信号 - errors_detected
  assign p_errors_detected = errors_detected;
  assign g_errors_detected = 16'h0001; // 添加1
  
  // 跳跃进位逻辑 - frames_sent
  assign c_frames_sent[0] = g_frames_sent[0];
  genvar i;
  generate
    for (i = 1; i < 16; i = i + 1) begin : carry_gen_sent
      assign c_frames_sent[i] = g_frames_sent[i] | (p_frames_sent[i] & c_frames_sent[i-1]);
    end
  endgenerate
  
  // 跳跃进位逻辑 - frames_received
  assign c_frames_received[0] = g_frames_received[0];
  generate
    for (i = 1; i < 16; i = i + 1) begin : carry_gen_received
      assign c_frames_received[i] = g_frames_received[i] | (p_frames_received[i] & c_frames_received[i-1]);
    end
  endgenerate
  
  // 跳跃进位逻辑 - errors_detected
  assign c_errors_detected[0] = g_errors_detected[0];
  generate
    for (i = 1; i < 16; i = i + 1) begin : carry_gen_errors
      assign c_errors_detected[i] = g_errors_detected[i] | (p_errors_detected[i] & c_errors_detected[i-1]);
    end
  endgenerate
  
  // 求和
  assign frames_sent_next = p_frames_sent ^ g_frames_sent ^ {c_frames_sent[14:0], 1'b0};
  assign frames_received_next = p_frames_received ^ g_frames_received ^ {c_frames_received[14:0], 1'b0};
  assign errors_detected_next = p_errors_detected ^ g_errors_detected ^ {c_errors_detected[14:0], 1'b0};
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      node_state <= ERROR_ACTIVE;
      frames_sent <= 0;
      frames_received <= 0;
      errors_detected <= 0;
    end else begin
      prev_tx_active <= tx_active;
      prev_rx_active <= rx_active;
      prev_error <= error_detected;
      
      if (!prev_tx_active && tx_active) frames_sent <= frames_sent_next;
      if (!prev_rx_active && rx_active) frames_received <= frames_received_next;
      if (!prev_error && error_detected) errors_detected <= errors_detected_next;
      
      node_state <= bus_off ? BUS_OFF : 
                   (tx_err_count > 127 || rx_err_count > 127) ? ERROR_PASSIVE : ERROR_ACTIVE;
    end
  end
endmodule