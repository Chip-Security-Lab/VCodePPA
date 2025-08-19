//SystemVerilog
module distributed_priority_intr_ctrl(
  input clk, rst,
  input [15:0] req_data,   // 输入请求数据
  input valid,             // 发送方数据有效信号
  output reg ready,        // 接收方就绪信号
  output reg [3:0] id,     // 输出优先级ID
  output reg id_valid,     // 输出ID有效信号
  input id_ready           // 接收方就绪信号
);
  wire [1:0] group_id;
  wire [3:0] group_req;
  wire [3:0] sub_id [0:3];
  wire [3:0] sub_valid;
  
  reg [15:0] req;          // 内部请求寄存器
  reg processing;          // 处理状态标志
  
  // Group-level priority detection
  assign group_req[0] = |req[3:0];
  assign group_req[1] = |req[7:4];
  assign group_req[2] = |req[11:8];
  assign group_req[3] = |req[15:12];
  
  // Sub-encoders
  assign sub_valid[0] = group_req[0];
  assign sub_id[0] = req[0] ? 4'd0 : (req[1] ? 4'd1 : (req[2] ? 4'd2 : 4'd3));
  
  assign sub_valid[1] = group_req[1];
  assign sub_id[1] = req[4] ? 4'd4 : (req[5] ? 4'd5 : (req[6] ? 4'd6 : 4'd7));
  
  assign sub_valid[2] = group_req[2];
  assign sub_id[2] = req[8] ? 4'd8 : (req[9] ? 4'd9 : (req[10] ? 4'd10 : 4'd11));
  
  assign sub_valid[3] = group_req[3];
  assign sub_id[3] = req[12] ? 4'd12 : (req[13] ? 4'd13 : (req[14] ? 4'd14 : 4'd15));
  
  // Group encoder
  assign group_id = group_req[0] ? 2'd0 : (group_req[1] ? 2'd1 : 
                   (group_req[2] ? 2'd2 : 2'd3));
  
  // Valid-Ready handshake logic
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      req <= 16'd0;
      ready <= 1'b1;
      id <= 4'd0;
      id_valid <= 1'b0;
      processing <= 1'b0;
    end else begin
      // 输入握手处理 - Valid-Ready协议
      if (valid && ready) begin
        req <= req_data;
        processing <= 1'b1;
        // 如果已经有数据待处理，保持ready为低
        ready <= 1'b0;
      end
      
      // 处理数据并准备输出
      if (processing && !id_valid) begin
        if (|group_req) begin
          id <= sub_id[group_id];
          id_valid <= 1'b1;
        end else begin
          // 无有效请求，恢复接收新请求的状态
          ready <= 1'b1;
          processing <= 1'b0;
        end
      end
      
      // 输出握手完成
      if (id_valid && id_ready) begin
        id_valid <= 1'b0;
        // 当前处理完成，可以接收新数据
        ready <= 1'b1;
        processing <= 1'b0;
      end
    end
  end
endmodule