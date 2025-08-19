//SystemVerilog
module prio_enc_function #(parameter W=16)(
  input [W-1:0] req,
  output [$clog2(W)-1:0] enc_addr
);

  wire [W-1:0] req_mask;
  wire [W-1:0] carry_chain;
  wire [W-1:0] sum_chain;
  
  // 子模块实例化
  rightmost_bit_detector #(.WIDTH(W)) u_rightmost_bit (
    .data_in(req),
    .mask_out(req_mask)
  );
  
  carry_chain_generator #(.WIDTH(W)) u_carry_chain (
    .req_mask(req_mask),
    .carry_chain(carry_chain),
    .sum_chain(sum_chain)
  );
  
  address_encoder #(.WIDTH(W)) u_encoder (
    .sum_chain(sum_chain),
    .enc_addr(enc_addr)
  );
  
endmodule

//------------------------------------------------
// 子模块1: 最右位1检测器
//------------------------------------------------
module rightmost_bit_detector #(parameter WIDTH=16)(
  input [WIDTH-1:0] data_in,
  output [WIDTH-1:0] mask_out
);
  
  // 检测最右侧的1并创建掩码
  assign mask_out = data_in & (~(data_in - 1'b1));
  
endmodule

//------------------------------------------------
// 子模块2: 曼彻斯特进位链生成器
//------------------------------------------------
module carry_chain_generator #(parameter WIDTH=16)(
  input [WIDTH-1:0] req_mask,
  output [WIDTH-1:0] carry_chain,
  output [WIDTH-1:0] sum_chain
);
  
  // 初始化进位和求和链
  assign carry_chain[0] = 1'b0;
  assign sum_chain[0] = req_mask[0];
  
  // 生成进位和求和链
  genvar i;
  generate
    for(i=1; i<WIDTH; i=i+1) begin : carry_chain_gen
      assign carry_chain[i] = req_mask[i-1] | (carry_chain[i-1] & ~req_mask[i-1]);
      assign sum_chain[i] = req_mask[i] ^ carry_chain[i];
    end
  endgenerate
  
endmodule

//------------------------------------------------
// 子模块3: 地址编码器
//------------------------------------------------
module address_encoder #(parameter WIDTH=16)(
  input [WIDTH-1:0] sum_chain,
  output reg [$clog2(WIDTH)-1:0] enc_addr
);
  
  // 使用并行编码方式提高性能
  always @(*) begin
    enc_addr = {$clog2(WIDTH){1'b0}};
    for(int j=0; j<WIDTH; j=j+1)
      if(sum_chain[j]) enc_addr = j[$clog2(WIDTH)-1:0];
  end
  
endmodule