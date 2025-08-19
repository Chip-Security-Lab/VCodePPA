//SystemVerilog
// IEEE 1364-2005 Verilog标准
module prio_enc_dynamic_mask #(parameter W=8)(
  input clk,
  input [W-1:0] mask,
  input [W-1:0] req,
  output reg [$clog2(W)-1:0] index
);

wire [W-1:0] masked_req;
reg [W-1:0] masked_req_reg;
wire [$clog2(W)-1:0] index_next;

// 先行借位减法器信号定义
wire [W-1:0] P; // 传播信号
wire [W-1:0] G; // 生成信号
wire [W:0] borrow; // 借位信号
wire [W-1:0] diff; // 差值
wire [W-1:0] minuend; // 被减数
wire [W-1:0] subtrahend; // 减数

// Pipeline stage 1: Mask operation
always @(posedge clk) begin
  masked_req_reg <= req & mask;
end

// 先行借位减法器实现
// 在这里我们实现的是一个特殊的减法器，用于优化优先编码器的实现
assign minuend = masked_req_reg;
assign subtrahend = {1'b0, masked_req_reg[W-1:1]}; // 右移一位

// 生成传播和生成信号
assign P = ~minuend; // 传播借位的条件
assign G = ~minuend & subtrahend; // 生成借位的条件

// 借位计算 - 先行借位链
assign borrow[0] = 1'b0; // 初始无借位
genvar i;
generate
  for (i = 0; i < W; i = i + 1) begin : gen_borrow
    assign borrow[i+1] = G[i] | (P[i] & borrow[i]);
  end
endgenerate

// 计算差值
assign diff = minuend ^ subtrahend ^ borrow[W-1:0];

// 优先编码逻辑 - 基于先行借位减法结果
assign index_next = 0;
generate
  for (i = 0; i < W; i = i + 1) begin : gen_priority
    // 通过减法结果找到第一个置位位置
    if (i > 0) begin
      assign index_next = diff[i] ? i[$clog2(W)-1:0] : index_next;
    end else begin
      assign index_next = masked_req_reg[0] ? 0 : index_next;
    end
  end
endgenerate

// Pipeline stage 2: 更新输出
always @(posedge clk) begin
  index <= index_next;
end

endmodule