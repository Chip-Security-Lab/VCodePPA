//SystemVerilog
//IEEE 1364-2005 Verilog
module fixed_priority_arbiter #(parameter N=4) (
  input wire clk, rst_n,
  input wire [N-1:0] req,
  output reg [N-1:0] grant
);
  
  reg [N-1:0] next_grant;
  
  // 添加缓冲寄存器，用于高扇出信号req
  reg [N-1:0] req_buf1, req_buf2;
  
  //----------------------------------------------------
  // 输入信号缓冲 - 将req信号注册到多个缓冲器
  //----------------------------------------------------
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_buf1 <= {N{1'b0}};
    end else begin
      req_buf1 <= req;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_buf2 <= {N{1'b0}};
    end else begin
      req_buf2 <= req;
    end
  end
  
  //----------------------------------------------------
  // 请求有效信号检测
  //----------------------------------------------------
  reg req_valid_buf;
  
  always @(*) begin
    req_valid_buf = |req_buf1;
  end
  
  //----------------------------------------------------
  // 固定优先级仲裁逻辑 - 使用级联优先级编码
  //----------------------------------------------------
  always @(*) begin
    next_grant = {N{1'b0}};
    
    if (req_valid_buf) begin
      if (req_buf2[0])
        next_grant[0] = 1'b1;
      else if (req_buf2[1])
        next_grant[1] = 1'b1;
      else if (req_buf2[2])
        next_grant[2] = 1'b1;
      else if (req_buf2[3])
        next_grant[3] = 1'b1;
    end
  end
  
  //----------------------------------------------------
  // next_grant的两级缓冲 - 低位和高位分别处理
  //----------------------------------------------------
  reg [N-1:0] next_grant_buf1, next_grant_buf2;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      next_grant_buf1 <= {N{1'b0}};
    end else begin
      next_grant_buf1 <= next_grant;
    end
  end
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      next_grant_buf2 <= {N{1'b0}};
    end else begin
      next_grant_buf2 <= next_grant;
    end
  end
  
  //----------------------------------------------------
  // 低位授权信号寄存 (bits 1:0)
  //----------------------------------------------------
  reg [1:0] grant_low;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant_low <= 2'b00;
    end else begin
      grant_low <= next_grant_buf1[1:0];  // 使用buf1驱动低位
    end
  end
  
  //----------------------------------------------------
  // 高位授权信号寄存 (bits 3:2)
  //----------------------------------------------------
  reg [1:0] grant_high;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant_high <= 2'b00;
    end else begin
      grant_high <= next_grant_buf2[3:2]; // 使用buf2驱动高位
    end
  end
  
  //----------------------------------------------------
  // 最终输出组合 - 合并高低位形成完整grant信号
  //----------------------------------------------------
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      grant <= {N{1'b0}};
    else
      grant <= {grant_high, grant_low};
  end
  
endmodule