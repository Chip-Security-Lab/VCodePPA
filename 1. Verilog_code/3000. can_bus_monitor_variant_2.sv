//SystemVerilog
//IEEE 1364-2005 Verilog
// 顶层模块
module can_bus_monitor(
  input wire clk, rst_n,
  input wire can_rx, can_tx,
  input wire frame_valid, error_detected,
  input wire [10:0] rx_id,
  input wire [7:0] rx_data [0:7],
  input wire [3:0] rx_dlc,
  output wire [15:0] frames_received,
  output wire [15:0] errors_detected,
  output wire [15:0] bus_load_percent,
  output wire [7:0] last_error_type
);

  // 内部连线
  wire frame_valid_sync1, error_detected_sync1, can_rx_sync1;
  wire frame_valid_sync2, error_detected_sync2, can_rx_sync2;
  wire frame_edge_stage1, error_edge_stage1;
  wire frame_edge_stage2, error_edge_stage2;

  // 信号同步子模块 - 增加流水线深度
  input_synchronizer sync_inst (
    .clk(clk),
    .rst_n(rst_n),
    .frame_valid_in(frame_valid),
    .error_detected_in(error_detected),
    .can_rx_in(can_rx),
    .frame_valid_out1(frame_valid_sync1),
    .error_detected_out1(error_detected_sync1),
    .can_rx_out1(can_rx_sync1),
    .frame_valid_out2(frame_valid_sync2),
    .error_detected_out2(error_detected_sync2),
    .can_rx_out2(can_rx_sync2)
  );

  // 边沿检测子模块 - 增加流水线深度
  edge_detector edge_inst (
    .clk(clk),
    .rst_n(rst_n),
    .frame_valid(frame_valid_sync2),
    .error_detected(error_detected_sync2),
    .frame_edge_stage1(frame_edge_stage1),
    .error_edge_stage1(error_edge_stage1),
    .frame_edge_stage2(frame_edge_stage2),
    .error_edge_stage2(error_edge_stage2)
  );

  // 帧计数器子模块 - 增加流水线深度
  frame_counter frame_count_inst (
    .clk(clk),
    .rst_n(rst_n),
    .frame_edge(frame_edge_stage2),
    .error_edge(error_edge_stage2),
    .frames_received(frames_received),
    .errors_detected(errors_detected),
    .last_error_type(last_error_type)
  );

  // 总线负载计算子模块 - 增加流水线深度
  bus_load_calculator bus_load_inst (
    .clk(clk),
    .rst_n(rst_n),
    .can_rx(can_rx_sync2),
    .bus_load_percent(bus_load_percent)
  );

endmodule

// 输入信号同步子模块 - 增加流水线深度
module input_synchronizer (
  input wire clk, rst_n,
  input wire frame_valid_in, error_detected_in, can_rx_in,
  output reg frame_valid_out1, error_detected_out1, can_rx_out1,
  output reg frame_valid_out2, error_detected_out2, can_rx_out2
);
  
  // 首级寄存器，捕获输入信号
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frame_valid_out1 <= 1'b0;
      error_detected_out1 <= 1'b0;
      can_rx_out1 <= 1'b1;
    end else begin
      frame_valid_out1 <= frame_valid_in;
      error_detected_out1 <= error_detected_in;
      can_rx_out1 <= can_rx_in;
    end
  end
  
  // 增加第二级流水线寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frame_valid_out2 <= 1'b0;
      error_detected_out2 <= 1'b0;
      can_rx_out2 <= 1'b1;
    end else begin
      frame_valid_out2 <= frame_valid_out1;
      error_detected_out2 <= error_detected_out1;
      can_rx_out2 <= can_rx_out1;
    end
  end
  
endmodule

// 边沿检测子模块 - 增加流水线深度
module edge_detector (
  input wire clk, rst_n,
  input wire frame_valid, error_detected,
  output reg frame_edge_stage1, error_edge_stage1,
  output reg frame_edge_stage2, error_edge_stage2
);

  reg prev_frame_valid_stage1, prev_error_stage1;
  reg prev_frame_valid_stage2, prev_error_stage2;
  
  // 流水线第一级 - 保存历史值
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_frame_valid_stage1 <= 1'b0;
      prev_error_stage1 <= 1'b0;
    end else begin
      prev_frame_valid_stage1 <= frame_valid;
      prev_error_stage1 <= error_detected;
    end
  end
  
  // 流水线第二级 - 计算边沿并寄存结果
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frame_edge_stage1 <= 1'b0;
      error_edge_stage1 <= 1'b0;
      prev_frame_valid_stage2 <= 1'b0;
      prev_error_stage2 <= 1'b0;
    end else begin
      frame_edge_stage1 <= !prev_frame_valid_stage1 && frame_valid;
      error_edge_stage1 <= !prev_error_stage1 && error_detected;
      prev_frame_valid_stage2 <= prev_frame_valid_stage1;
      prev_error_stage2 <= prev_error_stage1;
    end
  end
  
  // 流水线第三级 - 寄存边沿检测结果
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frame_edge_stage2 <= 1'b0;
      error_edge_stage2 <= 1'b0;
    end else begin
      frame_edge_stage2 <= frame_edge_stage1;
      error_edge_stage2 <= error_edge_stage1;
    end
  end
  
endmodule

// 帧计数器子模块 - 增加流水线深度
module frame_counter (
  input wire clk, rst_n,
  input wire frame_edge, error_edge,
  output reg [15:0] frames_received,
  output reg [15:0] errors_detected,
  output reg [7:0] last_error_type
);
  
  reg frame_edge_stage1, error_edge_stage1;
  reg [15:0] frames_received_stage1;
  reg [15:0] errors_detected_stage1;
  
  // 流水线第一级 - 寄存输入信号
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frame_edge_stage1 <= 1'b0;
      error_edge_stage1 <= 1'b0;
    end else begin
      frame_edge_stage1 <= frame_edge;
      error_edge_stage1 <= error_edge;
    end
  end
  
  // 流水线第二级 - 计算计数值
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frames_received_stage1 <= 16'h0;
      errors_detected_stage1 <= 16'h0;
    end else begin
      // 计数帧接收
      if (frame_edge_stage1)
        frames_received_stage1 <= frames_received + 1'b1;
      else
        frames_received_stage1 <= frames_received;
        
      // 计数错误
      if (error_edge_stage1)
        errors_detected_stage1 <= errors_detected + 1'b1;
      else
        errors_detected_stage1 <= errors_detected;
    end
  end
  
  // 流水线第三级 - 输出最终结果
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      frames_received <= 16'h0;
      errors_detected <= 16'h0;
      last_error_type <= 8'h0;
    end else begin
      frames_received <= frames_received_stage1;
      errors_detected <= errors_detected_stage1;
      
      // 更新错误类型 - 在实际应用中会基于具体错误标志设置
      if (error_edge_stage1)
        last_error_type <= 8'h1; // 示例值
    end
  end
  
endmodule

// 总线负载计算子模块 - 增加流水线深度
module bus_load_calculator #(
  parameter SAMPLE_PERIOD = 1000  // 参数化采样周期
)(
  input wire clk, rst_n,
  input wire can_rx,
  output reg [15:0] bus_load_percent
);
  
  reg [31:0] total_bits_stage1, active_bits_stage1;
  reg [31:0] total_bits_stage2, active_bits_stage2;
  reg [31:0] total_bits_stage3, active_bits_stage3;
  reg can_rx_stage1, can_rx_stage2;
  reg sample_complete_stage1, sample_complete_stage2, sample_complete_stage3;
  
  // 流水线第一级 - 捕获输入和累计采样
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      can_rx_stage1 <= 1'b1;
      total_bits_stage1 <= 32'h0;
      active_bits_stage1 <= 32'h0;
      sample_complete_stage1 <= 1'b0;
    end else begin
      can_rx_stage1 <= can_rx;
      
      // 累计采样位
      total_bits_stage1 <= (total_bits_stage3 >= SAMPLE_PERIOD) ? 32'h1 : total_bits_stage3 + 1'b1;
      active_bits_stage1 <= (total_bits_stage3 >= SAMPLE_PERIOD) ? (!can_rx ? 32'h1 : 32'h0) : 
                                                                  (active_bits_stage3 + (!can_rx ? 1'b1 : 1'b0));
      
      // 检测采样周期完成
      sample_complete_stage1 <= (total_bits_stage3 >= SAMPLE_PERIOD);
    end
  end
  
  // 流水线第二级 - 寄存计算中间值
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      can_rx_stage2 <= 1'b1;
      total_bits_stage2 <= 32'h0;
      active_bits_stage2 <= 32'h0;
      sample_complete_stage2 <= 1'b0;
    end else begin
      can_rx_stage2 <= can_rx_stage1;
      total_bits_stage2 <= total_bits_stage1;
      active_bits_stage2 <= active_bits_stage1;
      sample_complete_stage2 <= sample_complete_stage1;
    end
  end
  
  // 流水线第三级 - 百分比计算准备
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      total_bits_stage3 <= 32'h0;
      active_bits_stage3 <= 32'h0;
      sample_complete_stage3 <= 1'b0;
    end else begin
      total_bits_stage3 <= total_bits_stage2;
      active_bits_stage3 <= active_bits_stage2;
      sample_complete_stage3 <= sample_complete_stage2;
    end
  end
  
  // 流水线第四级 - 计算总线负载百分比
  reg [31:0] load_calculation;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      load_calculation <= 32'h0;
      bus_load_percent <= 16'h0;
    end else begin
      if (sample_complete_stage3) begin
        // 分解计算过程以减少单级计算复杂度
        load_calculation <= (active_bits_stage3 * 100);
      end
      
      // 最后一级，完成除法操作并输出结果
      if (sample_complete_stage3) begin
        bus_load_percent <= (load_calculation / total_bits_stage3);
      end
    end
  end
  
endmodule