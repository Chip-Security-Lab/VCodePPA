//SystemVerilog
// 顶层模块
module nested_intr_ctrl (
  input                 clk,
  input                 rst_n,
  input        [7:0]    intr_req,
  input        [7:0]    intr_mask,
  input        [15:0]   intr_priority, // 2 bits per interrupt
  input                 intr_ready,    // 替代原来的ack信号
  output       [2:0]    intr_id,
  output                intr_valid     // 替代原来的req信号
);

  // 内部信号
  wire         [7:0]    pending;
  wire         [1:0]    current_level;
  wire                  handshake_done;
  
  // 握手完成信号 - 当valid和ready同时为高时表示握手完成
  assign handshake_done = intr_valid && intr_ready;

  // 中断请求处理模块实例
  intr_request_handler u_request_handler (
    .clk          (clk),
    .rst_n        (rst_n),
    .intr_req     (intr_req),
    .intr_mask    (intr_mask),
    .handshake_done (handshake_done),  // 替代原来的ack信号
    .intr_id      (intr_id),
    .pending      (pending)
  );

  // 优先级编码器模块实例
  priority_encoder u_priority_encoder (
    .clk          (clk),
    .rst_n        (rst_n),
    .pending      (pending),
    .intr_priority(intr_priority),
    .intr_ready   (intr_ready),       // 新增ready信号
    .intr_id      (intr_id),
    .intr_valid   (intr_valid),       // 更改为valid信号
    .current_level(current_level)
  );

endmodule

// 中断请求处理模块
module intr_request_handler (
  input                 clk,
  input                 rst_n,
  input        [7:0]    intr_req,
  input        [7:0]    intr_mask,
  input                 handshake_done,  // 替代原来的ack信号
  input        [2:0]    intr_id,
  output reg   [7:0]    pending
);

  // 处理中断请求和确认
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending <= 8'h0;
    end else begin
      // 设置中断请求标志
      pending <= pending | (intr_req & intr_mask);
      
      // 清除已确认的中断
      if (handshake_done) pending[intr_id] <= 1'b0;
    end
  end

endmodule

// 优先级编码器模块
module priority_encoder (
  input                 clk,
  input                 rst_n,
  input        [7:0]    pending,
  input        [15:0]   intr_priority,
  input                 intr_ready,      // 新增ready信号输入
  output reg   [2:0]    intr_id,
  output reg            intr_valid,      // 更改为valid信号
  output reg   [1:0]    current_level
);

  integer i;
  reg [2:0] next_intr_id;
  reg [1:0] next_level;
  reg       next_valid;

  // 优先级编码逻辑 - 组合逻辑部分
  always @(*) begin
    next_valid = 1'b0;
    next_level = 2'b11; // 默认为最低优先级
    next_intr_id = 3'b0;
    
    // 优先级编码 - 从高优先级到低优先级
    for (i = 0; i < 8; i = i + 1) begin
      if (pending[i] && intr_priority[i*2+:2] < next_level) begin
        next_intr_id = i[2:0];
        next_level = intr_priority[i*2+:2];
        next_valid = 1'b1;
      end
    end
  end
  
  // 时序逻辑部分
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_level <= 2'b11; // 最低优先级
      intr_id <= 3'b0;
      intr_valid <= 1'b0;
    end else begin
      // 当handshake完成或当前没有valid信号时，更新状态
      if ((intr_valid && intr_ready) || !intr_valid) begin
        current_level <= next_level;
        intr_id <= next_intr_id;
        intr_valid <= next_valid;
      end
      // 否则保持当前状态，直到接收方准备好
    end
  end

endmodule