//SystemVerilog
module token_ring_arbiter(
  // AXI-Stream 接口
  input wire                 clk,
  input wire                 rst,
  
  // 请求输入接口
  input wire [3:0]           s_axis_tdata,
  input wire                 s_axis_tvalid,
  output wire                s_axis_tready,
  
  // 授权输出接口
  output wire [3:0]          m_axis_tdata,
  output wire                m_axis_tvalid,
  input wire                 m_axis_tready,
  output wire                m_axis_tlast,
  
  // 令牌状态输出
  output wire [1:0]          token
);

  // 流水线阶段寄存器
  // 第一级：输入请求阶段
  reg [3:0]  req_stage1;
  reg        valid_stage1;
  
  // 第二级：令牌处理阶段
  reg [3:0]  req_stage2;
  reg        valid_stage2;
  reg [1:0]  token_stage2;
  
  // 第三级：授权生成阶段
  reg [3:0]  grant_stage3;
  reg        valid_stage3;
  reg [1:0]  token_stage3;
  
  // 第四级：输出阶段
  reg [3:0]  grant_stage4;
  reg        valid_stage4;
  reg [1:0]  token_stage4;
  
  // 流水线控制信号
  wire stage1_ready;
  wire stage2_ready;
  wire stage3_ready;
  wire stage4_ready;
  
  // 流水线反压控制
  assign stage4_ready = !valid_stage4 || m_axis_tready;
  assign stage3_ready = !valid_stage3 || stage4_ready;
  assign stage2_ready = !valid_stage2 || stage3_ready;
  assign stage1_ready = !valid_stage1 || stage2_ready;
  
  // 输入接口控制
  assign s_axis_tready = stage1_ready;
  
  // 流水线第一级：捕获输入请求
  always @(posedge clk) begin
    if (rst) begin
      req_stage1 <= 4'b0000;
      valid_stage1 <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tready) begin
      req_stage1 <= s_axis_tdata;
      valid_stage1 <= 1'b1;
    end else if (valid_stage1 && stage2_ready) begin
      valid_stage1 <= 1'b0;
    end
  end
  
  // 流水线第二级：保存请求，准备处理
  always @(posedge clk) begin
    if (rst) begin
      req_stage2 <= 4'b0000;
      valid_stage2 <= 1'b0;
      token_stage2 <= 2'd0;
    end else if (valid_stage1 && stage2_ready) begin
      req_stage2 <= req_stage1;
      valid_stage2 <= 1'b1;
      token_stage2 <= token_stage4; // 使用当前令牌状态
    end else if (valid_stage2 && stage3_ready) begin
      valid_stage2 <= 1'b0;
    end
  end
  
  // 流水线第三级：令牌环仲裁逻辑
  always @(posedge clk) begin
    if (rst) begin
      grant_stage3 <= 4'd0;
      valid_stage3 <= 1'b0;
      token_stage3 <= 2'd0;
    end else if (valid_stage2 && stage3_ready) begin
      valid_stage3 <= 1'b1;
      grant_stage3 <= 4'd0;
      token_stage3 <= token_stage2;
      
      case (token_stage2)
        2'd0: if (req_stage2[0]) begin
                grant_stage3[0] <= 1'b1;
                token_stage3 <= 2'd0;
              end
              else if (req_stage2[1]) begin 
                grant_stage3[1] <= 1'b1; 
                token_stage3 <= 2'd1; 
              end
              else if (req_stage2[2]) begin 
                grant_stage3[2] <= 1'b1; 
                token_stage3 <= 2'd2; 
              end
              else if (req_stage2[3]) begin 
                grant_stage3[3] <= 1'b1; 
                token_stage3 <= 2'd3; 
              end
              else begin
                valid_stage3 <= valid_stage2;
              end
              
        2'd1: if (req_stage2[1]) begin
                grant_stage3[1] <= 1'b1;
                token_stage3 <= 2'd1;
              end
              else if (req_stage2[2]) begin 
                grant_stage3[2] <= 1'b1; 
                token_stage3 <= 2'd2; 
              end
              else if (req_stage2[3]) begin 
                grant_stage3[3] <= 1'b1; 
                token_stage3 <= 2'd3; 
              end
              else if (req_stage2[0]) begin 
                grant_stage3[0] <= 1'b1; 
                token_stage3 <= 2'd0; 
              end
              else begin
                valid_stage3 <= valid_stage2;
              end
              
        2'd2: if (req_stage2[2]) begin
                grant_stage3[2] <= 1'b1;
                token_stage3 <= 2'd2;
              end
              else if (req_stage2[3]) begin 
                grant_stage3[3] <= 1'b1; 
                token_stage3 <= 2'd3; 
              end
              else if (req_stage2[0]) begin 
                grant_stage3[0] <= 1'b1; 
                token_stage3 <= 2'd0; 
              end
              else if (req_stage2[1]) begin 
                grant_stage3[1] <= 1'b1; 
                token_stage3 <= 2'd1; 
              end
              else begin
                valid_stage3 <= valid_stage2;
              end
              
        2'd3: if (req_stage2[3]) begin
                grant_stage3[3] <= 1'b1;
                token_stage3 <= 2'd3;
              end
              else if (req_stage2[0]) begin 
                grant_stage3[0] <= 1'b1; 
                token_stage3 <= 2'd0; 
              end
              else if (req_stage2[1]) begin 
                grant_stage3[1] <= 1'b1; 
                token_stage3 <= 2'd1; 
              end
              else if (req_stage2[2]) begin 
                grant_stage3[2] <= 1'b1; 
                token_stage3 <= 2'd2; 
              end
              else begin
                valid_stage3 <= valid_stage2;
              end
      endcase
    end else if (valid_stage3 && stage4_ready) begin
      valid_stage3 <= 1'b0;
    end
  end
  
  // 流水线第四级：输出阶段
  always @(posedge clk) begin
    if (rst) begin
      grant_stage4 <= 4'd0;
      valid_stage4 <= 1'b0;
      token_stage4 <= 2'd0;
    end else if (valid_stage3 && stage4_ready) begin
      grant_stage4 <= grant_stage3;
      valid_stage4 <= valid_stage3 && (|grant_stage3);
      token_stage4 <= token_stage3;
    end else if (valid_stage4 && m_axis_tready) begin
      valid_stage4 <= 1'b0;
    end
  end
  
  // 输出信号连接
  assign m_axis_tdata = grant_stage4;
  assign m_axis_tvalid = valid_stage4;
  assign m_axis_tlast = 1'b1; // 每次授权是一个完整事务
  assign token = token_stage4;
  
endmodule