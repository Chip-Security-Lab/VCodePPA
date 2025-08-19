//SystemVerilog
//-----------------------------------------------------------------------------
// 顶层模块: 优先级编码器主控模块
//-----------------------------------------------------------------------------
module prio_enc_sync_rst #(
  parameter WIDTH = 8,  // 输入请求宽度
  parameter ADDR  = 3   // 输出地址宽度
)(
  input                  clk,      // 时钟信号
  input                  rst_n,    // 低电平有效复位
  input      [WIDTH-1:0] req_in,   // 请求输入信号
  output reg [ADDR-1:0]  addr_out  // 地址输出
);

  // 内部连线
  wire [ADDR-1:0] encoded_addr;
  wire            valid_request;

  // 实例化请求处理模块
  request_detector #(
    .WIDTH(WIDTH)
  ) req_detect_inst (
    .req_in        (req_in),
    .valid_request (valid_request)
  );

  // 实例化编码逻辑模块
  priority_encoder #(
    .WIDTH(WIDTH),
    .ADDR(ADDR)
  ) encoder_inst (
    .req_in       (req_in),
    .encoded_addr (encoded_addr)
  );

  // 实例化输出控制模块
  output_controller #(
    .ADDR(ADDR)
  ) out_ctrl_inst (
    .clk          (clk),
    .rst_n        (rst_n),
    .valid_request(valid_request),
    .encoded_addr (encoded_addr),
    .addr_out     (addr_out)
  );

endmodule

//-----------------------------------------------------------------------------
// 子模块: 请求检测模块
//-----------------------------------------------------------------------------
module request_detector #(
  parameter WIDTH = 8  // 输入请求宽度
)(
  input  [WIDTH-1:0] req_in,        // 请求输入信号
  output             valid_request  // 有效请求指示
);

  // 使用归约或操作检测有效请求
  assign valid_request = |req_in;

endmodule

//-----------------------------------------------------------------------------
// 子模块: 优先级编码逻辑模块
//-----------------------------------------------------------------------------
module priority_encoder #(
  parameter WIDTH = 8,  // 输入请求宽度
  parameter ADDR  = 3   // 输出地址宽度
)(
  input  [WIDTH-1:0] req_in,        // 请求输入信号
  output [ADDR-1:0]  encoded_addr   // 编码地址结果
);

  // 内部信号
  reg [ADDR-1:0] addr_comb;
  reg [WIDTH-1:0] mask;
  integer i;

  // 优化后的组合逻辑实现优先级编码
  always @(*) begin
    addr_comb = {ADDR{1'b0}}; // 默认值
    mask = {WIDTH{1'b1}};     // 初始掩码全1
    
    // 使用掩码技术优化比较链
    for (i = WIDTH-1; i >= 0; i = i-1) begin
      if (req_in[i] && mask[i]) begin
        addr_comb = i[ADDR-1:0];
        mask = {WIDTH{1'b0}}; // 找到最高优先级后停止搜索
      end
    end
  end

  // 输出赋值
  assign encoded_addr = addr_comb;

endmodule

//-----------------------------------------------------------------------------
// 子模块: 输出控制模块
//-----------------------------------------------------------------------------
module output_controller #(
  parameter ADDR = 3  // 地址宽度
)(
  input             clk,           // 时钟信号
  input             rst_n,         // 低电平有效复位
  input             valid_request, // 有效请求指示
  input  [ADDR-1:0] encoded_addr,  // 编码地址输入
  output reg [ADDR-1:0] addr_out   // 地址输出
);

  // 时序逻辑处理输出寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      addr_out <= {ADDR{1'b0}};
    end else begin
      // 仅在有有效请求时更新输出
      if (valid_request) begin
        addr_out <= encoded_addr;
      end else begin
        addr_out <= {ADDR{1'b0}};
      end
    end
  end

endmodule