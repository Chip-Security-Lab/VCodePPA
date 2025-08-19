//SystemVerilog
module reset_event_counter (
  input  wire        clk,
  input  wire        reset_n,
  
  // AXI-Stream output interface
  output wire [7:0]  m_axis_tdata,
  output wire        m_axis_tvalid,
  input  wire        m_axis_tready,
  output wire        m_axis_tlast
);

  // 内部连接信号
  wire [7:0] reset_count;
  wire       reset_detected;
  
  // 实例化子模块
  reset_detector u_reset_detector (
    .clk            (clk),
    .reset_n        (reset_n),
    .reset_count    (reset_count),
    .reset_detected (reset_detected)
  );
  
  axis_transmitter u_axis_transmitter (
    .clk            (clk),
    .reset_n        (reset_n),
    .reset_detected (reset_detected),
    .reset_count    (reset_count),
    .m_axis_tdata   (m_axis_tdata),
    .m_axis_tvalid  (m_axis_tvalid),
    .m_axis_tready  (m_axis_tready),
    .m_axis_tlast   (m_axis_tlast)
  );

endmodule

// 复位检测子模块
module reset_detector (
  input  wire        clk,
  input  wire        reset_n,
  output reg  [7:0]  reset_count,
  output reg         reset_detected
);

  // 复位事件计数和检测逻辑
  always @(posedge clk) begin
    if (!reset_n) begin
      reset_count <= reset_count + 1'b1;
      reset_detected <= 1'b1;
    end else begin
      reset_detected <= 1'b0;
    end
  end

endmodule

// AXI-Stream传输控制子模块
module axis_transmitter (
  input  wire        clk,
  input  wire        reset_n,
  input  wire        reset_detected,
  input  wire [7:0]  reset_count,
  output reg  [7:0]  m_axis_tdata,
  output reg         m_axis_tvalid,
  input  wire        m_axis_tready,
  output reg         m_axis_tlast
);

  // 传输状态跟踪
  reg data_sent;
  
  // AXI-Stream握手和数据传输控制
  always @(posedge clk) begin
    if (!reset_n) begin
      m_axis_tvalid <= 1'b0;
      m_axis_tlast <= 1'b0;
      data_sent <= 1'b0;
    end else begin
      if (reset_detected && !data_sent) begin
        // 当检测到复位且数据尚未发送时
        m_axis_tdata <= reset_count;
        m_axis_tvalid <= 1'b1;
        m_axis_tlast <= 1'b1;  // 每次复位事件一次传输
        
        if (m_axis_tvalid && m_axis_tready) begin
          data_sent <= 1'b1;
        end
      end else if (!reset_detected) begin
        data_sent <= 1'b0;
        m_axis_tvalid <= 1'b0;
        m_axis_tlast <= 1'b0;
      end else if (m_axis_tvalid && m_axis_tready) begin
        // 成功握手后，取消有效信号
        m_axis_tvalid <= 1'b0;
        m_axis_tlast <= 1'b0;
      end
    end
  end

endmodule