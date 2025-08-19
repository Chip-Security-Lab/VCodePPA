//SystemVerilog
// 顶层模块
module daisy_chain_intr_ctrl(
  input clk, rst_n,
  input [3:0] requests,
  input chain_in,
  output [1:0] local_id,
  output chain_out,
  output grant
);
  // 内部连线
  wire local_req;
  wire [1:0] local_id_next;
  wire local_req_buf1, local_req_buf2;
  wire [1:0] local_id_buf1, local_id_buf2;
  
  // 子模块实例化
  request_priority_encoder priority_encoder (
    .requests(requests),
    .local_req(local_req),
    .local_id_next(local_id_next)
  );
  
  signal_buffering buffer_stage (
    .clk(clk),
    .rst_n(rst_n),
    .local_req_in(local_req),
    .local_id_next_in(local_id_next),
    .local_req_buf1(local_req_buf1),
    .local_req_buf2(local_req_buf2),
    .local_id_buf1(local_id_buf1),
    .local_id_buf2(local_id_buf2),
    .local_id_out(local_id)
  );
  
  chain_control chain_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .chain_in(chain_in),
    .local_req_buf1(local_req_buf1),
    .local_req_buf2(local_req_buf2),
    .chain_out(chain_out),
    .grant(grant)
  );
  
endmodule

// 请求优先级编码器子模块
module request_priority_encoder(
  input [3:0] requests,
  output reg local_req,
  output reg [1:0] local_id_next
);
  // 确定本地请求和优先级ID
  always @(*) begin
    local_req = |requests;
    casez (requests)
      4'b???1: local_id_next = 2'd0;
      4'b??10: local_id_next = 2'd1;
      4'b?100: local_id_next = 2'd2;
      4'b1000: local_id_next = 2'd3;
      default: local_id_next = 2'd0;
    endcase
  end
endmodule

// 信号缓冲子模块
module signal_buffering(
  input clk, rst_n,
  input local_req_in,
  input [1:0] local_id_next_in,
  output reg local_req_buf1, local_req_buf2,
  output reg [1:0] local_id_buf1, local_id_buf2,
  output reg [1:0] local_id_out
);
  // 高扇出信号的缓冲寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      local_req_buf1 <= 1'b0;
      local_req_buf2 <= 1'b0;
      local_id_buf1 <= 2'd0;
      local_id_buf2 <= 2'd0;
      local_id_out <= 2'd0;
    end else begin
      local_req_buf1 <= local_req_in;
      local_req_buf2 <= local_req_in;
      local_id_buf1 <= local_id_next_in;
      local_id_buf2 <= local_id_next_in;
      local_id_out <= local_id_next_in;
    end
  end
endmodule

// 链路控制子模块
module chain_control(
  input clk, rst_n,
  input chain_in,
  input local_req_buf1, local_req_buf2,
  output chain_out,
  output reg grant
);
  // 使用缓冲信号计算chain_out
  assign chain_out = chain_in & ~local_req_buf1;
  
  // 使用缓冲信号计算grant
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      grant <= 1'b0;
    else
      grant <= local_req_buf2 & chain_in;
  end
endmodule