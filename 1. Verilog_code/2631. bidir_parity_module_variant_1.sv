//SystemVerilog
// 顶层模块
module bidir_parity_module(
  input [15:0] data,
  input even_odd_sel,  // 0-even, 1-odd
  output parity_out
);
  
  wire xor_parity;
  
  // 计算基础奇偶校验位
  parity_calculator parity_calc_inst (
    .data(data),
    .parity_out(xor_parity)
  );
  
  // 根据选择信号转换奇偶性
  parity_selector parity_sel_inst (
    .parity_in(xor_parity),
    .even_odd_sel(even_odd_sel),
    .parity_out(parity_out)
  );
  
endmodule

// 奇偶校验计算子模块
module parity_calculator (
  input [15:0] data,
  output parity_out
);
  
  // 优化XOR树结构以减少关键路径延迟
  wire [7:0] level1;
  wire [3:0] level2;
  wire [1:0] level3;
  
  // 第一级 XOR 运算 (8个并行运算)
  generate
    genvar i;
    for (i = 0; i < 8; i = i + 1) begin : GEN_LEVEL1
      assign level1[i] = data[i*2] ^ data[i*2+1];
    end
  endgenerate
  
  // 第二级 XOR 运算 (4个并行运算)
  generate
    for (i = 0; i < 4; i = i + 1) begin : GEN_LEVEL2
      assign level2[i] = level1[i*2] ^ level1[i*2+1];
    end
  endgenerate
  
  // 第三级 XOR 运算 (2个并行运算)
  assign level3[0] = level2[0] ^ level2[1];
  assign level3[1] = level2[2] ^ level2[3];
  
  // 最终 XOR 运算
  assign parity_out = level3[0] ^ level3[1];
  
endmodule

// 奇偶性选择子模块
module parity_selector (
  input parity_in,
  input even_odd_sel,  // 0-even, 1-odd
  output parity_out
);
  
  // 根据选择控制信号翻转奇偶位
  assign parity_out = even_odd_sel ? ~parity_in : parity_in;
  
endmodule