//SystemVerilog
//IEEE 1364-2005
module prio_enc_gray_error #(parameter N=8)(
  input [N-1:0] req,
  output reg [$clog2(N)-1:0] gray_out,
  output error
);
  wire [$clog2(N)-1:0] bin_out;
  reg [$clog2(N)-1:0] bin_temp;
  wire req_valid;
  wire [$clog2(N)-1:0] shifted_bin;

  // 将多个always块合并为一个，包含优先编码和格雷码转换
  always @(*) begin
    // 优先编码器部分
    bin_temp = {$clog2(N){1'b0}};
    case (1'b1) // 优先级编码使用case语句而非循环
      req[7]: bin_temp = 3'd7;
      req[6]: bin_temp = 3'd6;
      req[5]: bin_temp = 3'd5;
      req[4]: bin_temp = 3'd4;
      req[3]: bin_temp = 3'd3;
      req[2]: bin_temp = 3'd2;
      req[1]: bin_temp = 3'd1;
      req[0]: bin_temp = 3'd0;
      default: bin_temp = {$clog2(N){1'b0}};
    endcase
    
    // 格雷码转换部分
    gray_out = (bin_out >> 1) ^ bin_out;
  end

  // 逻辑简化
  assign req_valid = |req;
  assign bin_out = req_valid ? bin_temp : {$clog2(N){1'b0}};
  assign error = ~req_valid;

endmodule