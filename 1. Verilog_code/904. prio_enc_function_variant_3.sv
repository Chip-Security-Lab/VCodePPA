//SystemVerilog
// SystemVerilog
// IEEE 1364-2005 Verilog标准
// 顶层模块
module prio_enc_function #(
  parameter W = 16
)(
  input [W-1:0] req,
  output [$clog2(W)-1:0] enc_addr,
  // 新增减法器接口
  input [7:0] minuend,
  input [7:0] subtrahend,
  output [7:0] difference
);
  
  // 内部信号
  wire [W-1:0] req_detected;
  wire valid_req;
  
  // 子模块实例化
  request_detector #(
    .W(W)
  ) u_request_detector (
    .req(req),
    .req_detected(req_detected),
    .valid_req(valid_req)
  );
  
  encoder #(
    .W(W)
  ) u_encoder (
    .req_detected(req_detected),
    .valid_req(valid_req),
    .enc_addr(enc_addr)
  );
  
  // 条件反相减法器实例
  conditional_subtractor u_conditional_subtractor (
    .minuend(minuend),
    .subtrahend(subtrahend),
    .difference(difference)
  );
  
endmodule

// 请求检测子模块
module request_detector #(
  parameter W = 16
)(
  input [W-1:0] req,
  output [W-1:0] req_detected,
  output valid_req
);
  
  // 从输入请求中获取最高优先级的请求
  genvar i;
  generate
    for (i = 0; i < W; i = i + 1) begin : gen_req_detect
      if (i == 0) begin : first_bit
        assign req_detected[i] = req[i];
      end else begin : other_bits
        assign req_detected[i] = req[i] & ~(|req[i-1:0]);
      end
    end
  endgenerate
  
  // 表示是否有有效请求
  assign valid_req = |req;
  
endmodule

// 编码器子模块
module encoder #(
  parameter W = 16
)(
  input [W-1:0] req_detected,
  input valid_req,
  output reg [$clog2(W)-1:0] enc_addr
);
  
  integer j;
  
  always @(*) begin
    enc_addr = {$clog2(W){1'b0}};
    
    if (valid_req) begin
      for (j = 0; j < W; j = j + 1) begin
        if (req_detected[j]) begin
          enc_addr = j[$clog2(W)-1:0];
        end
      end
    end
  end
  
endmodule

// 条件反相减法器 - 8位
module conditional_subtractor (
  input [7:0] minuend,
  input [7:0] subtrahend,
  output [7:0] difference
);
  // 内部信号
  wire [7:0] inverted_subtrahend;
  wire [7:0] conditional_value;
  wire [8:0] sum_with_carry; // 包含进位的和
  
  // 对被减数取反
  assign inverted_subtrahend = ~subtrahend;
  
  // 使用条件反相减法算法
  // 通过加1实现二进制补码
  assign sum_with_carry = minuend + inverted_subtrahend + 8'h01;
  
  // 最终结果
  assign difference = sum_with_carry[7:0];
  
endmodule