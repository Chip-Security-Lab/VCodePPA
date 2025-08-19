//SystemVerilog
// SystemVerilog
// IEEE 1364-2005
module prio_enc_fsm #(parameter WIDTH=6)(
  input clk, rst,
  input [WIDTH-1:0] in,
  output reg [$clog2(WIDTH)-1:0] addr,
  output reg valid_out
);

// 流水线状态和控制信号
localparam IDLE = 2'b00;
localparam STAGE1 = 2'b01;
localparam STAGE2 = 2'b10;
localparam STAGE3 = 2'b11;

reg [1:0] state;
reg [WIDTH-1:0] in_stage1, in_stage2;
reg valid_stage1, valid_stage2;
reg [$clog2(WIDTH)-1:0] priority_addr_stage2, priority_addr_stage3;

// 临时变量
reg [$clog2(WIDTH)-1:0] tmp_addr;
reg found;
integer i;

// 第一级流水线：输入寄存和初始检测
always @(posedge clk) begin
  if (rst) begin
    state <= IDLE;
    in_stage1 <= 0;
    valid_stage1 <= 0;
  end else begin
    if (state == IDLE) begin
      if (|in) begin
        state <= STAGE1;
        in_stage1 <= in;
        valid_stage1 <= 1;
      end else begin
        valid_stage1 <= 0;
      end
    end else if (state == STAGE1) begin
      in_stage1 <= in;
      valid_stage1 <= |in;
      state <= STAGE2;
    end else if (state == STAGE2) begin
      in_stage1 <= in;
      valid_stage1 <= |in;
      state <= STAGE3;
    end else if (state == STAGE3) begin
      in_stage1 <= in;
      valid_stage1 <= |in;
      state <= STAGE1;
    end else begin
      state <= IDLE;
      valid_stage1 <= 0;
    end
  end
end

// 第二级流水线：扫描优先级
always @(posedge clk) begin
  if (rst) begin
    valid_stage2 <= 0;
    in_stage2 <= 0;
    priority_addr_stage2 <= 0;
  end else begin
    in_stage2 <= in_stage1;
    valid_stage2 <= valid_stage1;
    
    // 计算优先级地址
    found = 0;
    tmp_addr = 0;
    
    // 高性能优先编码器逻辑 - 分段处理
    for (i = 0; i < WIDTH/2; i = i + 1) begin
      if (in_stage1[i] && !found) begin
        tmp_addr = i[$clog2(WIDTH)-1:0];
        found = 1;
      end
    end
    
    priority_addr_stage2 <= tmp_addr;
  end
end

// 第三级流水线：继续扫描并输出结果
always @(posedge clk) begin
  if (rst) begin
    priority_addr_stage3 <= 0;
    valid_out <= 0;
    addr <= 0;
  end else begin
    // 处理后半部分的优先级编码
    found = 0;
    tmp_addr = priority_addr_stage2;
    
    // 高性能优先编码器逻辑 - 处理第二部分
    for (i = WIDTH/2; i < WIDTH; i = i + 1) begin
      if (in_stage2[i] && !found) begin
        tmp_addr = i[$clog2(WIDTH)-1:0];
        found = 1;
      end
    end
    
    priority_addr_stage3 <= tmp_addr;
    
    // 输出结果
    addr <= priority_addr_stage3;
    valid_out <= valid_stage2;
  end
end

endmodule