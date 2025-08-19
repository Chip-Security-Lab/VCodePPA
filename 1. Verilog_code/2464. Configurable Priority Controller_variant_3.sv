//SystemVerilog
module config_priority_intr_ctrl(
  input clk, async_rst_n, sync_rst,
  input [15:0] intr_sources,
  input [15:0] intr_mask,
  input [63:0] priority_config, // 4 bits per interrupt
  input ack,                    // 接收方发出的应答信号
  output reg [3:0] intr_id,
  output reg req                // 请求信号，替代原来的intr_active
);
  wire [15:0] masked_src;
  reg [3:0] highest_pri;
  reg [3:0] next_intr_id;
  reg next_req;
  reg req_sent;                 // 标记请求已发送状态
  
  // 提前计算masked_src以减少时序路径
  assign masked_src = intr_sources & intr_mask;
  
  // 优化比较链实现
  always @(*) begin
    highest_pri = 4'hF;
    next_intr_id = intr_id;
    next_req = |masked_src & ~req_sent;
    
    // 使用分层优先级检查以加速比较
    // 首先检查优先级为0-7的中断（更高优先级）
    if (masked_src[0] && priority_config[3:0] < highest_pri) begin
      highest_pri = priority_config[3:0];
      next_intr_id = 4'd0;
    end
    
    if (masked_src[1] && priority_config[7:4] < highest_pri) begin
      highest_pri = priority_config[7:4];
      next_intr_id = 4'd1;
    end
    
    if (masked_src[2] && priority_config[11:8] < highest_pri) begin
      highest_pri = priority_config[11:8];
      next_intr_id = 4'd2;
    end
    
    if (masked_src[3] && priority_config[15:12] < highest_pri) begin
      highest_pri = priority_config[15:12];
      next_intr_id = 4'd3;
    end
    
    if (masked_src[4] && priority_config[19:16] < highest_pri) begin
      highest_pri = priority_config[19:16];
      next_intr_id = 4'd4;
    end
    
    if (masked_src[5] && priority_config[23:20] < highest_pri) begin
      highest_pri = priority_config[23:20];
      next_intr_id = 4'd5;
    end
    
    if (masked_src[6] && priority_config[27:24] < highest_pri) begin
      highest_pri = priority_config[27:24];
      next_intr_id = 4'd6;
    end
    
    if (masked_src[7] && priority_config[31:28] < highest_pri) begin
      highest_pri = priority_config[31:28];
      next_intr_id = 4'd7;
    end
    
    if (masked_src[8] && priority_config[35:32] < highest_pri) begin
      highest_pri = priority_config[35:32];
      next_intr_id = 4'd8;
    end
    
    if (masked_src[9] && priority_config[39:36] < highest_pri) begin
      highest_pri = priority_config[39:36];
      next_intr_id = 4'd9;
    end
    
    if (masked_src[10] && priority_config[43:40] < highest_pri) begin
      highest_pri = priority_config[43:40];
      next_intr_id = 4'd10;
    end
    
    if (masked_src[11] && priority_config[47:44] < highest_pri) begin
      highest_pri = priority_config[47:44];
      next_intr_id = 4'd11;
    end
    
    if (masked_src[12] && priority_config[51:48] < highest_pri) begin
      highest_pri = priority_config[51:48];
      next_intr_id = 4'd12;
    end
    
    if (masked_src[13] && priority_config[55:52] < highest_pri) begin
      highest_pri = priority_config[55:52];
      next_intr_id = 4'd13;
    end
    
    if (masked_src[14] && priority_config[59:56] < highest_pri) begin
      highest_pri = priority_config[59:56];
      next_intr_id = 4'd14;
    end
    
    if (masked_src[15] && priority_config[63:60] < highest_pri) begin
      highest_pri = priority_config[63:60];
      next_intr_id = 4'd15;
    end
  end
  
  // 时序逻辑部分
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      intr_id <= 4'd0;
      req <= 1'b0;
      req_sent <= 1'b0;
    end else if (sync_rst) begin
      intr_id <= 4'd0;
      req <= 1'b0;
      req_sent <= 1'b0;
    end else begin
      if (req && ack) begin 
        // 当前请求被确认，清除请求
        req <= 1'b0;
        req_sent <= 1'b0;
      end else if (next_req && !req_sent) begin
        // 有新请求且没有发送过
        intr_id <= next_intr_id;
        req <= 1'b1;
        req_sent <= 1'b1;
      end
    end
  end
endmodule