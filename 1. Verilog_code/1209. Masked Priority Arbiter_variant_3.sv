//SystemVerilog - IEEE 1364-2005
module masked_priority_arbiter(
  input wire clk, rst_n,
  input wire [3:0] req,
  input wire [3:0] mask,
  output reg [3:0] grant
);
  // 内部信号定义
  reg [3:0] req_reg;
  reg [3:0] mask_reg;
  wire [3:0] masked_req;
  reg [3:0] next_grant;
  
  // 输入请求信号注册
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      req_reg <= 4'h0;
    end
    else begin
      req_reg <= req;
    end
  end
  
  // 掩码信号注册
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mask_reg <= 4'h0;
    end
    else begin
      mask_reg <= mask;
    end
  end
  
  // 生成掩码后的请求信号
  assign masked_req = req_reg & ~mask_reg;
  
  // 优先级仲裁逻辑 - 通道0 (最高优先级)
  always @(*) begin
    next_grant = 4'h0; // 默认无授权
    if (masked_req[0]) begin
      next_grant[0] = 1'b1;
    end
    else if (masked_req[1]) begin
      next_grant[1] = 1'b1;
    end
    else if (masked_req[2]) begin
      next_grant[2] = 1'b1;
    end
    else if (masked_req[3]) begin
      next_grant[3] = 1'b1;
    end
  end
  
  // 输出授权信号注册
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant <= 4'h0;
    end
    else begin
      grant <= next_grant;
    end
  end

endmodule