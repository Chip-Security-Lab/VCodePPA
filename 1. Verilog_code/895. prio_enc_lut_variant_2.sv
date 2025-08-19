//SystemVerilog
// IEEE 1364-2005 Verilog标准
module prio_enc_lut #(parameter DEPTH=8)(
  input [DEPTH-1:0] in,
  output reg [$clog2(DEPTH)-1:0] out
);

  // 扁平化的条件结构
  always @(*) begin
    out = {$clog2(DEPTH){1'b0}}; // 默认输出全0
    
    if (DEPTH == 8 && in[7]) out = 3'd7;
    else if (DEPTH == 8 && in[6]) out = 3'd6;
    else if (DEPTH == 8 && in[5]) out = 3'd5;
    else if (DEPTH == 8 && in[4]) out = 3'd4;
    else if (DEPTH == 8 && in[3]) out = 3'd3;
    else if (DEPTH == 8 && in[2]) out = 3'd2;
    else if (DEPTH == 8 && in[1]) out = 3'd1;
    else if (DEPTH == 8 && in[0]) out = 3'd0;
    else begin
      // 通用方法优化，避免循环
      // 从高位到低位检查
      integer i;
      for(i=DEPTH-1; i>=0; i=i-1)
        if(in[i]) out = i[$clog2(DEPTH)-1:0];
    end
  end
endmodule