//SystemVerilog
module token_ring_arbiter(
  // AXI-Stream接口
  input wire clk, rst,
  // AXI-Stream 输入
  input wire s_axis_tvalid,
  output wire s_axis_tready,
  input wire [3:0] s_axis_tdata,  // 请求信号作为输入数据
  // AXI-Stream 输出
  output reg m_axis_tvalid,
  input wire m_axis_tready,
  output reg [5:0] m_axis_tdata,  // [5:4]=token, [3:0]=grant
  output reg m_axis_tlast
);

  // 寄存器移动到组合逻辑之后
  reg [1:0] token;
  reg [3:0] grant;
  reg processing_done;
  
  // 输入数据寄存器
  reg [3:0] s_axis_tdata_reg;
  reg s_axis_tvalid_reg;
  
  // 组合逻辑部分
  reg [3:0] next_grant;
  reg [1:0] next_token;
  reg next_processing_done;
  reg next_m_axis_tvalid;
  reg [5:0] next_m_axis_tdata;
  reg next_m_axis_tlast;
  
  // 准备接收新数据
  assign s_axis_tready = !processing_done || m_axis_tready;
  
  // 输入寄存器化
  always @(posedge clk) begin
    if (rst) begin
      s_axis_tdata_reg <= 4'd0;
      s_axis_tvalid_reg <= 1'b0;
    end else if (s_axis_tready) begin
      s_axis_tdata_reg <= s_axis_tdata;
      s_axis_tvalid_reg <= s_axis_tvalid;
    end
  end
  
  // 组合逻辑实现仲裁算法
  always @(*) begin
    next_grant = grant;
    next_token = token;
    next_processing_done = processing_done;
    next_m_axis_tvalid = m_axis_tvalid;
    next_m_axis_tdata = m_axis_tdata;
    next_m_axis_tlast = m_axis_tlast;
    
    // 处理新请求
    if (s_axis_tvalid_reg && (!processing_done || m_axis_tready)) begin
      next_grant = 4'd0;
      next_processing_done = 1'b1;
      
      case (token)
        2'd0: if (s_axis_tdata_reg[0]) next_grant[0] = 1'b1;
              else if (s_axis_tdata_reg[1]) begin next_grant[1] = 1'b1; next_token = 2'd1; end
              else if (s_axis_tdata_reg[2]) begin next_grant[2] = 1'b1; next_token = 2'd2; end
              else if (s_axis_tdata_reg[3]) begin next_grant[3] = 1'b1; next_token = 2'd3; end
        2'd1: if (s_axis_tdata_reg[1]) next_grant[1] = 1'b1;
              else if (s_axis_tdata_reg[2]) begin next_grant[2] = 1'b1; next_token = 2'd2; end
              else if (s_axis_tdata_reg[3]) begin next_grant[3] = 1'b1; next_token = 2'd3; end
              else if (s_axis_tdata_reg[0]) begin next_grant[0] = 1'b1; next_token = 2'd0; end
        2'd2: if (s_axis_tdata_reg[2]) next_grant[2] = 1'b1;
              else if (s_axis_tdata_reg[3]) begin next_grant[3] = 1'b1; next_token = 2'd3; end
              else if (s_axis_tdata_reg[0]) begin next_grant[0] = 1'b1; next_token = 2'd0; end
              else if (s_axis_tdata_reg[1]) begin next_grant[1] = 1'b1; next_token = 2'd1; end
        2'd3: if (s_axis_tdata_reg[3]) next_grant[3] = 1'b1;
              else if (s_axis_tdata_reg[0]) begin next_grant[0] = 1'b1; next_token = 2'd0; end
              else if (s_axis_tdata_reg[1]) begin next_grant[1] = 1'b1; next_token = 2'd1; end
              else if (s_axis_tdata_reg[2]) begin next_grant[2] = 1'b1; next_token = 2'd2; end
      endcase
      
      // 准备输出数据
      next_m_axis_tvalid = 1'b1;
      next_m_axis_tdata = {next_token, next_grant};
      next_m_axis_tlast = 1'b1;  // 表示一次完整的仲裁结果
    end
    
    // 输出握手完成，重置状态
    if (m_axis_tvalid && m_axis_tready) begin
      next_m_axis_tvalid = 1'b0;
      next_m_axis_tlast = 1'b0;
      next_processing_done = 1'b0;
    end
  end
  
  // 输出寄存器更新
  always @(posedge clk) begin
    if (rst) begin
      token <= 2'd0;
      grant <= 4'd0;
      m_axis_tvalid <= 1'b0;
      m_axis_tdata <= 6'd0;
      m_axis_tlast <= 1'b0;
      processing_done <= 1'b0;
    end else begin
      token <= next_token;
      grant <= next_grant;
      m_axis_tvalid <= next_m_axis_tvalid;
      m_axis_tdata <= next_m_axis_tdata;
      m_axis_tlast <= next_m_axis_tlast;
      processing_done <= next_processing_done;
    end
  end
endmodule