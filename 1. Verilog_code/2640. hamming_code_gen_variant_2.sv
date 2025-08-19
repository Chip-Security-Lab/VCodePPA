//SystemVerilog
//顶层模块
module hamming_code_gen(
  input [3:0] data_in,
  output [6:0] hamming_out
);
  wire [2:0] parity_bits;
  wire [3:0] data_bits;

  // 实例化奇偶校验位生成子模块
  parity_generator parity_gen(
    .data_in(data_in),
    .parity_out(parity_bits)
  );

  // 实例化数据位放置子模块
  data_placer data_place(
    .data_in(data_in),
    .data_out(data_bits)
  );

  // 实例化输出组装子模块
  output_assembler out_assemble(
    .parity_bits(parity_bits),
    .data_bits(data_bits),
    .hamming_out(hamming_out)
  );
endmodule

// 奇偶校验位生成子模块
module parity_generator(
  input [3:0] data_in,
  output [2:0] parity_out
);
  // P1: 位0,1,3的奇偶校验
  assign parity_out[0] = data_in[0] ^ data_in[1] ^ data_in[3];

  // P2: 位0,2,3的奇偶校验
  assign parity_out[1] = data_in[0] ^ data_in[2] ^ data_in[3];

  // P4: 位1,2,3的奇偶校验
  assign parity_out[2] = data_in[1] ^ data_in[2] ^ data_in[3];
endmodule

// 数据位放置子模块
module data_placer(
  input [3:0] data_in,
  output [3:0] data_out
);
  // 对应hamming码中的数据位位置
  assign data_out[0] = data_in[0]; // 位置3
  assign data_out[1] = data_in[1]; // 位置5
  assign data_out[2] = data_in[2]; // 位置6
  assign data_out[3] = data_in[3]; // 位置7
endmodule

// 输出组装子模块
module output_assembler(
  input [2:0] parity_bits,
  input [3:0] data_bits,
  output [6:0] hamming_out
);
  // 组装最终的汉明码
  assign hamming_out[0] = parity_bits[0]; // P1
  assign hamming_out[1] = parity_bits[1]; // P2
  assign hamming_out[2] = data_bits[0];   // D1
  assign hamming_out[3] = parity_bits[2]; // P4
  assign hamming_out[4] = data_bits[1];   // D2
  assign hamming_out[5] = data_bits[2];   // D3
  assign hamming_out[6] = data_bits[3];   // D4
endmodule