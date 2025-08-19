//SystemVerilog
// 顶层模块：CAN远程帧处理器
module can_remote_frame_handler (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        rx_rtr,
  input  wire        rx_id_valid,
  input  wire [10:0] rx_id,
  output wire [10:0] tx_request_id,
  output wire        tx_data_ready,
  output wire        tx_request
);

  // 内部连线
  wire [10:0] config_response_id [0:3];
  wire [3:0]  config_response_mask;
  
  // 配置子模块实例化
  can_rtr_config config_unit (
    .clk            (clk),
    .rst_n          (rst_n),
    .response_id    (config_response_id),
    .response_mask  (config_response_mask)
  );
  
  // ID匹配与响应生成子模块实例化
  can_rtr_matcher matcher_unit (
    .clk            (clk),
    .rst_n          (rst_n),
    .rx_rtr         (rx_rtr),
    .rx_id_valid    (rx_id_valid),
    .rx_id          (rx_id),
    .response_id    (config_response_id),
    .response_mask  (config_response_mask),
    .tx_request_id  (tx_request_id),
    .tx_data_ready  (tx_data_ready),
    .tx_request     (tx_request)
  );

endmodule

// 配置子模块：管理响应ID和掩码配置
module can_rtr_config (
  input  wire        clk,
  input  wire        rst_n,
  output reg  [10:0] response_id [0:3],
  output reg  [3:0]  response_mask
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      response_mask <= 4'b0101; // 示例：响应特定的RTR
      
      // 我们将响应的ID列表
      response_id[0] <= 11'h100;
      response_id[1] <= 11'h200;
      response_id[2] <= 11'h300;
      response_id[3] <= 11'h400;
    end
  end

endmodule

// ID匹配与响应生成子模块
module can_rtr_matcher (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        rx_rtr,
  input  wire        rx_id_valid,
  input  wire [10:0] rx_id,
  input  wire [10:0] response_id [0:3],
  input  wire [3:0]  response_mask,
  output reg  [10:0] tx_request_id,
  output reg         tx_data_ready,
  output reg         tx_request
);

  // 内部信号
  reg  [3:0] id_equal;       // 第一级流水线：ID比较结果
  reg  [3:0] response_mask_r; // 寄存器化的掩码
  reg  [3:0] id_match;       // 第二级流水线：ID匹配结果
  reg        any_match;      // 第三级流水线：任意匹配结果
  
  // 延迟控制信号
  reg        rx_rtr_d1, rx_rtr_d2;
  reg        rx_id_valid_d1, rx_id_valid_d2;
  reg [10:0] rx_id_d1, rx_id_d2;
  
  // 第一级流水线：ID比较
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_equal <= 4'b0;
      response_mask_r <= 4'b0;
      rx_rtr_d1 <= 1'b0;
      rx_id_valid_d1 <= 1'b0;
      rx_id_d1 <= 11'h0;
    end else begin
      // 寄存器化比较结果，分解复杂的组合逻辑路径
      id_equal[0] <= (rx_id == response_id[0]);
      id_equal[1] <= (rx_id == response_id[1]);
      id_equal[2] <= (rx_id == response_id[2]);
      id_equal[3] <= (rx_id == response_id[3]);
      
      // 寄存器化掩码以匹配时序路径
      response_mask_r <= response_mask;
      
      // 延迟控制信号与数据
      rx_rtr_d1 <= rx_rtr;
      rx_id_valid_d1 <= rx_id_valid;
      rx_id_d1 <= rx_id;
    end
  end
  
  // 第二级流水线：应用掩码进行匹配
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_match <= 4'b0;
      rx_rtr_d2 <= 1'b0;
      rx_id_valid_d2 <= 1'b0;
      rx_id_d2 <= 11'h0;
    end else begin
      // 寄存器化掩码与比较结果的组合
      id_match[0] <= id_equal[0] & response_mask_r[0];
      id_match[1] <= id_equal[1] & response_mask_r[1];
      id_match[2] <= id_equal[2] & response_mask_r[2];
      id_match[3] <= id_equal[3] & response_mask_r[3];
      
      // 继续延迟控制信号
      rx_rtr_d2 <= rx_rtr_d1;
      rx_id_valid_d2 <= rx_id_valid_d1;
      rx_id_d2 <= rx_id_d1;
    end
  end
  
  // 第三级流水线：计算任意匹配
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      any_match <= 1'b0;
    end else begin
      // 寄存器化OR归约操作
      any_match <= |id_match;
    end
  end
  
  // 响应生成逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_data_ready <= 1'b0;
      tx_request <= 1'b0;
      tx_request_id <= 11'h0;
    end else begin
      tx_request <= 1'b0;
      
      // 使用流水线信号生成响应
      if (rx_id_valid_d2 && rx_rtr_d2 && any_match) begin
        tx_request_id <= rx_id_d2;
        tx_data_ready <= 1'b1;
        tx_request <= 1'b1;
      end
    end
  end

endmodule