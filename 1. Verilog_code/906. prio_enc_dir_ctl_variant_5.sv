//SystemVerilog
module prio_enc_dir_ctl #(parameter N=8)(
  input clk, dir, // 0:LSB-first 1:MSB-first
  input [N-1:0] req,
  output reg [$clog2(N)-1:0] index
);

  wire [$clog2(N)-1:0] msb_index, lsb_index;
  wire [N-1:0] reversed_req;
  wire valid;
  
  // 对请求信号求或，判断是否有有效请求
  assign valid = |req;
  
  // 反转请求信号用于MSB优先模式
  genvar j;
  generate
    for (j = 0; j < N; j = j + 1) begin : reverse_gen
      assign reversed_req[j] = req[N-1-j];
    end
  endgenerate
  
  // 优化的LSB优先查找逻辑
  casez_priority_encoder lsb_encoder (
    .req(req),
    .index(lsb_index)
  );
  
  // 优化的MSB优先查找逻辑
  casez_priority_encoder msb_encoder (
    .req(reversed_req),
    .index(msb_index)
  );
  
  // 更新输出
  always @(posedge clk) begin
    if (!valid) begin
      index <= 0;
    end else if (dir) begin // MSB first
      index <= N-1-msb_index; // 调整MSB优先模式的索引
    end else begin // LSB first
      index <= lsb_index;
    end
  end
  
endmodule

// 优化的优先编码器子模块，使用casez实现
module casez_priority_encoder #(parameter N=8)(
  input [N-1:0] req,
  output reg [$clog2(N)-1:0] index
);

  always @(*) begin
    casez(req)
      // 以下是生成的优先级编码模式
      8'b00000001: index = 0;
      8'b0000001?: index = 1;
      8'b000001??: index = 2;
      8'b00001???: index = 3;
      8'b0001????: index = 4;
      8'b001?????: index = 5;
      8'b01??????: index = 6;
      8'b1???????: index = 7;
      default: index = 0;
    endcase
  end
  
endmodule