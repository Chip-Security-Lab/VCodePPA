//SystemVerilog
module hier_parity_gen(
  input [31:0] wide_data,
  output parity,
  input req,         // 请求信号
  output valid,      // 有效信号
  output ack,        // 应答信号
  input ready        // 准备信号
);
  wire p_lower, p_upper;

  // 生成有效信号
  assign valid = req;

  // 生成准备信号
  assign ack = ready;

  // 子模块实例化：处理低16位数据的奇偶校验
  parity_16bit lower_parity (
    .data(wide_data[15:0]),
    .parity_out(p_lower)
  );

  // 子模块实例化：处理高16位数据的奇偶校验
  parity_16bit upper_parity (
    .data(wide_data[31:16]),
    .parity_out(p_upper)
  );

  // 最终奇偶校验结果
  parity_combine final_parity (
    .parity_a(p_lower),
    .parity_b(p_upper),
    .parity_out(parity)
  );
endmodule

// 16位数据的奇偶校验子模块
module parity_16bit (
  input [15:0] data,
  output parity_out
);
  // 参数化设计，可配置计算方式
  parameter IMPLEMENTATION = "DIRECT"; // 可选："DIRECT", "TREE"

  generate
    if (IMPLEMENTATION == "DIRECT") begin
      // 直接异或实现
      assign parity_out = ^data;
    end else begin
      // 树形结构实现，可提高性能
      wire [7:0] p_stage1;
      wire [3:0] p_stage2;
      wire [1:0] p_stage3;

      // 第一级：8个2位异或
      assign p_stage1[0] = data[0] ^ data[1];
      assign p_stage1[1] = data[2] ^ data[3];
      assign p_stage1[2] = data[4] ^ data[5];
      assign p_stage1[3] = data[6] ^ data[7];
      assign p_stage1[4] = data[8] ^ data[9];
      assign p_stage1[5] = data[10] ^ data[11];
      assign p_stage1[6] = data[12] ^ data[13];
      assign p_stage1[7] = data[14] ^ data[15];

      // 第二级：4个2位异或
      assign p_stage2[0] = p_stage1[0] ^ p_stage1[1];
      assign p_stage2[1] = p_stage1[2] ^ p_stage1[3];
      assign p_stage2[2] = p_stage1[4] ^ p_stage1[5];
      assign p_stage2[3] = p_stage1[6] ^ p_stage1[7];

      // 第三级：2个2位异或
      assign p_stage3[0] = p_stage2[0] ^ p_stage2[1];
      assign p_stage3[1] = p_stage2[2] ^ p_stage2[3];

      // 最终结果
      assign parity_out = p_stage3[0] ^ p_stage3[1];
    end
  endgenerate
endmodule

// 组合两个奇偶校验位的子模块
module parity_combine (
  input parity_a,
  input parity_b,
  output parity_out
);
  assign parity_out = parity_a ^ parity_b;
endmodule