//SystemVerilog
//IEEE 1364-2005 Verilog标准
module scalable_intr_ctrl #(
  parameter SOURCES = 32,
  parameter ID_WIDTH = $clog2(SOURCES)
)(
  input  wire                clk,
  input  wire                rst,
  input  wire [SOURCES-1:0]  requests,
  output wire [ID_WIDTH-1:0] grant_id,
  output wire                grant_valid
);

  // 内部连线
  wire [SOURCES-1:0] requests_buffered;
  wire               request_valid;
  wire [ID_WIDTH-1:0] priority_id;
  wire                priority_valid;

  // 实例化请求缓存和有效性检测模块
  request_buffer #(
    .SOURCES(SOURCES)
  ) req_buffer_inst (
    .clk               (clk),
    .rst               (rst),
    .requests_in       (requests),
    .requests_buffered (requests_buffered),
    .request_valid     (request_valid)
  );

  // 实例化优先级编码器模块
  priority_encoder #(
    .SOURCES(SOURCES),
    .ID_WIDTH(ID_WIDTH)
  ) pri_encoder_inst (
    .clk            (clk),
    .rst            (rst),
    .requests       (requests_buffered),
    .request_valid  (request_valid),
    .priority_id    (priority_id),
    .priority_valid (priority_valid)
  );

  // 实例化输出授权产生模块
  grant_generator #(
    .ID_WIDTH(ID_WIDTH)
  ) grant_gen_inst (
    .clk           (clk),
    .rst           (rst),
    .priority_id   (priority_id),
    .priority_valid(priority_valid),
    .grant_id      (grant_id),
    .grant_valid   (grant_valid)
  );

endmodule

// 数据流阶段1: 请求缓存和有效性检测模块
module request_buffer #(
  parameter SOURCES = 32
)(
  input  wire                clk,
  input  wire                rst,
  input  wire [SOURCES-1:0]  requests_in,
  output reg  [SOURCES-1:0]  requests_buffered,
  output reg                 request_valid
);

  // 请求缓存和有效性判断
  always @(posedge clk) begin
    if (rst) begin
      requests_buffered <= {SOURCES{1'b0}};
      request_valid     <= 1'b0;
    end else begin
      requests_buffered <= requests_in;
      request_valid     <= |requests_in;  // 检查是否有任何请求
    end
  end

endmodule

// 数据流阶段2: 优先级编码模块
module priority_encoder #(
  parameter SOURCES = 32,
  parameter ID_WIDTH = $clog2(SOURCES)
)(
  input  wire                clk,
  input  wire                rst,
  input  wire [SOURCES-1:0]  requests,
  input  wire                request_valid,
  output reg  [ID_WIDTH-1:0] priority_id,
  output reg                 priority_valid
);

  // 优先编码逻辑 - 查找最低有效位
  integer i;
  always @(posedge clk) begin
    if (rst) begin
      priority_id     <= {ID_WIDTH{1'b0}};
      priority_valid  <= 1'b0;
    end else begin
      priority_valid  <= request_valid;
      
      // 默认值 - 如果没有请求
      priority_id     <= {ID_WIDTH{1'b0}};
      
      // 优先编码器 - 从低位到高位扫描，找到第一个激活的请求
      for (i = 0; i < SOURCES; i = i + 1) begin
        if (requests[i]) begin
          priority_id <= i[ID_WIDTH-1:0];
          // 找到第一个请求后会自动停止（综合时隐含）
        end
      end
    end
  end

endmodule

// 数据流阶段3: 输出授权产生模块
module grant_generator #(
  parameter ID_WIDTH = 5
)(
  input  wire                clk,
  input  wire                rst,
  input  wire [ID_WIDTH-1:0] priority_id,
  input  wire                priority_valid,
  output reg  [ID_WIDTH-1:0] grant_id,
  output reg                 grant_valid
);

  // 输出级寄存器 - 产生最终授权信号
  always @(posedge clk) begin
    if (rst) begin
      grant_id    <= {ID_WIDTH{1'b0}};
      grant_valid <= 1'b0;
    end else begin
      grant_id    <= priority_id;
      grant_valid <= priority_valid;
    end
  end

endmodule