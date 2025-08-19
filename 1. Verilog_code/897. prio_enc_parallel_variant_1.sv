//SystemVerilog
// IEEE 1364-2005 Verilog standard
module prio_enc_parallel #(parameter N=16)(
  input [N-1:0] req,
  output reg [$clog2(N)-1:0] index
);
  // 优化计算前导1的位置
  // 直接使用or-reduce方法构建索引
  
  always @(*) begin
    index = 0;
    // 优化的布尔表达式实现，避免使用lead_one中间变量
    // 使用层次化的OR结构以降低逻辑深度
    if (req[15:8] != 0) begin
      if (req[15:12] != 0) begin
        if (req[15:14] != 0) begin
          index[3] = 1'b1;
          index[0] = ~req[15];
        end else begin
          index[3:2] = 2'b01;
          index[0] = ~req[13];
        end
        index[1] = ~(req[15] | req[13]);
      end else begin
        if (req[11:10] != 0) begin
          index[3:2] = 2'b01;
          index[1] = 1'b1;
          index[0] = ~req[11];
        end else begin
          index[3:2] = 2'b01;
          index[1:0] = {1'b0, ~req[9]};
        end
      end
    end else if (req[7:0] != 0) begin
      if (req[7:4] != 0) begin
        if (req[7:6] != 0) begin
          index[2:1] = 2'b11;
          index[0] = ~req[7];
        end else begin
          index[2:1] = 2'b10;
          index[0] = ~req[5];
        end
      end else begin
        if (req[3:2] != 0) begin
          index[2] = 1'b0;
          index[1] = 1'b1;
          index[0] = ~req[3];
        end else begin
          index[2:1] = 2'b00;
          index[0] = req[1];
        end
      end
    end
  end
endmodule