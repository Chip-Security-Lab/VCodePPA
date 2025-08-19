//SystemVerilog
// IEEE 1364-2005 Verilog Standard
module prio_enc_async_en #(parameter BITS=4)(
  input arst, en,
  input [BITS-1:0] din,
  output reg [$clog2(BITS)-1:0] dout
);

  wire [BITS-1:0] din_masked;
  wire [BITS-1:0] negated_input;
  wire negative_flag;

  // 条件反相减法器实现
  // 检测是否需要对输入进行取反
  assign negative_flag = din[BITS-1];
  
  // 根据条件决定是否对输入进行取反
  assign negated_input = negative_flag ? ~din + 1'b1 : din;
  
  // 对有效输入进行掩码处理
  assign din_masked = en ? negated_input : {BITS{1'b0}};

  // 优先级编码器 - 直接对处理后的输入进行编码
  always @(*) begin
    if (arst) begin
      dout = {$clog2(BITS){1'b0}};
    end
    else begin
      casez (din_masked)
        {BITS{1'b0}}: dout = {$clog2(BITS){1'b0}};
        {{(BITS-1){1'b0}}, 1'b1}: dout = 0;
        {{(BITS-2){1'b0}}, 1'b1, 1'b0}: dout = 1;
        {{(BITS-3){1'b0}}, 1'b1, {2{1'b0}}}: dout = 2;
        {{(BITS-4){1'b0}}, 1'b1, {3{1'b0}}}: dout = 3;
        default: dout = 0;
      endcase
    end
  end

endmodule