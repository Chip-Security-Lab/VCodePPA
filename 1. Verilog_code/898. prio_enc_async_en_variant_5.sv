//SystemVerilog
module prio_enc_async_en #(parameter BITS=8)(
  input arst, en,
  input [BITS-1:0] din,
  output reg [$clog2(BITS)-1:0] dout
);
  
  // 使用组合逻辑优先编码器
  always @(*) begin
    if (arst) begin
      dout = {$clog2(BITS){1'b0}};
    end
    else if (en) begin
      // 优化的优先编码器逻辑 - 使用casez
      casez(din)
        8'b1???????: dout = 3'd7;
        8'b01??????: dout = 3'd6;
        8'b001?????: dout = 3'd5;
        8'b0001????: dout = 3'd4;
        8'b00001???: dout = 3'd3;
        8'b000001??: dout = 3'd2;
        8'b0000001?: dout = 3'd1;
        8'b00000001: dout = 3'd0;
        default:     dout = {$clog2(BITS){1'b0}};
      endcase
    end
    else begin
      dout = {$clog2(BITS){1'b0}};
    end
  end
endmodule