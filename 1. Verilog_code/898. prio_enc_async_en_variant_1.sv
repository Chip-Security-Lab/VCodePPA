//SystemVerilog
// IEEE 1364-2005 Verilog标准
module prio_enc_async_en #(parameter BITS=4)(
  input arst, en,
  input [BITS-1:0] din,
  output reg [$clog2(BITS)-1:0] dout
);

  // 内部信号定义
  wire valid_input;
  wire [$clog2(BITS)-1:0] priority_value;
  
  // 实例化输入检测子模块
  input_valid_detector #(BITS) u_input_valid_detector(
    .din(din),
    .valid_input(valid_input)
  );
  
  // 实例化优先级编码子模块
  priority_encoder #(BITS) u_priority_encoder(
    .din(din),
    .priority_value(priority_value)
  );
  
  // 实例化输出控制子模块
  output_controller #(BITS) u_output_controller(
    .arst(arst),
    .en(en),
    .valid_input(valid_input),
    .priority_value(priority_value),
    .dout(dout)
  );

endmodule

// 输入有效性检测子模块
module input_valid_detector #(parameter BITS=4)(
  input [BITS-1:0] din,
  output reg valid_input
);
  
  always @(*) begin
    valid_input = 1'b0;
    for(integer i=0; i<BITS; i=i+1)
      if(din[i]) valid_input = 1'b1;
  end
  
endmodule

// 优先级编码子模块
module priority_encoder #(parameter BITS=4)(
  input [BITS-1:0] din,
  output reg [$clog2(BITS)-1:0] priority_value
);
  
  always @(*) begin
    priority_value = {$clog2(BITS){1'b0}};
    for(integer j=BITS-1; j>=0; j=j-1)
      if(din[j]) priority_value = j[$clog2(BITS)-1:0];
  end
  
endmodule

// 输出控制子模块
module output_controller #(parameter BITS=4)(
  input arst, en, valid_input,
  input [$clog2(BITS)-1:0] priority_value,
  output reg [$clog2(BITS)-1:0] dout
);
  
  always @(*) begin
    if(arst)
      dout = {$clog2(BITS){1'b0}};
    else if(en && valid_input)
      dout = priority_value;
    else
      dout = {$clog2(BITS){1'b0}};
  end
  
endmodule