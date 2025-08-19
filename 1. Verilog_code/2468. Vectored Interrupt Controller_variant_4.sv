//SystemVerilog
// SystemVerilog
module vectored_intr_ctrl #(
  parameter SOURCES = 16,
  parameter VEC_WIDTH = 8
)(
  input clk, rstn,
  input [SOURCES-1:0] intr_src,
  input [SOURCES*VEC_WIDTH-1:0] vector_table,
  output reg [VEC_WIDTH-1:0] intr_vector,
  output reg valid
);
  wire [VEC_WIDTH-1:0] next_intr_vector;
  wire next_valid;
  
  // Priority encoder with parallel prefix subtractor
  parallel_priority_encoder #(
    .SOURCES(SOURCES),
    .VEC_WIDTH(VEC_WIDTH)
  ) prio_encoder (
    .intr_src(intr_src),
    .vector_table(vector_table),
    .intr_vector(next_intr_vector),
    .valid(next_valid)
  );
  
  // 输出向量寄存器逻辑
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      intr_vector <= {VEC_WIDTH{1'b0}};
    end else begin
      intr_vector <= next_intr_vector;
    end
  end
  
  // 有效信号寄存器逻辑
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      valid <= 1'b0;
    end else begin
      valid <= next_valid;
    end
  end
endmodule

module parallel_priority_encoder #(
  parameter SOURCES = 16,
  parameter VEC_WIDTH = 8
)(
  input [SOURCES-1:0] intr_src,
  input [SOURCES*VEC_WIDTH-1:0] vector_table,
  output [VEC_WIDTH-1:0] intr_vector,
  output valid
);
  wire [SOURCES-1:0] priority_mask;
  wire [7:0] loop_index;
  wire [7:0] next_loop_index;
  
  // 生成优先级掩码逻辑
  assign priority_mask[SOURCES-1] = intr_src[SOURCES-1];
  
  genvar g;
  generate
    for (g = SOURCES-2; g >= 0; g = g - 1) begin : gen_priority
      assign priority_mask[g] = intr_src[g] & ~(|intr_src[SOURCES-1:g+1]);
    end
  endgenerate
  
  // 检测是否有中断激活
  assign valid = |intr_src;
  
  // 初始化循环索引用于减法器
  assign loop_index = SOURCES - 1;
  
  // 并行前缀减法器计算循环索引
  parallel_prefix_subtractor subtractor (
    .a(loop_index),
    .b(8'd1),
    .result(next_loop_index)
  );
  
  // 基于优先级选择合适的向量
  vector_selector #(
    .SOURCES(SOURCES),
    .VEC_WIDTH(VEC_WIDTH)
  ) vec_sel (
    .priority_mask(priority_mask),
    .vector_table(vector_table),
    .selected_vector(intr_vector)
  );
endmodule

// 新增的向量选择器模块
module vector_selector #(
  parameter SOURCES = 16,
  parameter VEC_WIDTH = 8
)(
  input [SOURCES-1:0] priority_mask,
  input [SOURCES*VEC_WIDTH-1:0] vector_table,
  output reg [VEC_WIDTH-1:0] selected_vector
);
  // 基于优先级选择合适的向量
  integer j;
  always @(*) begin
    selected_vector = {VEC_WIDTH{1'b0}};
    for (j = 0; j < SOURCES; j = j + 1) begin
      if (priority_mask[j]) begin
        selected_vector = vector_table[j*VEC_WIDTH+:VEC_WIDTH];
      end
    end
  end
endmodule

module parallel_prefix_subtractor (
  input [7:0] a,
  input [7:0] b,
  output [7:0] result
);
  wire [7:0] b_complement;
  wire [7:0] p, g;
  wire [7:0] p_level1, g_level1;
  wire [7:0] p_level2, g_level2;
  wire [7:0] p_level3, g_level3;
  wire [7:0] carry;
  
  // 计算二进制补码
  assign b_complement = ~b + 1'b1;
  
  // 生成传播和生成信号
  assign p = a ^ b_complement;
  assign g = a & b_complement;
  
  // 第一级前缀计算
  prefix_level1_computation prefix_comp_l1 (
    .p(p),
    .g(g),
    .p_level1(p_level1),
    .g_level1(g_level1)
  );
  
  // 第二级前缀计算
  prefix_level2_computation prefix_comp_l2 (
    .p_level1(p_level1),
    .g_level1(g_level1),
    .p_level2(p_level2),
    .g_level2(g_level2)
  );
  
  // 第三级前缀计算
  prefix_level3_computation prefix_comp_l3 (
    .p_level2(p_level2),
    .g_level2(g_level2),
    .p_level3(p_level3),
    .g_level3(g_level3)
  );
  
  // 计算进位
  carry_computation carry_comp (
    .g_level3(g_level3),
    .carry(carry)
  );
  
  // 计算结果
  assign result = p ^ carry;
endmodule

// 第一级前缀计算模块
module prefix_level1_computation (
  input [7:0] p,
  input [7:0] g,
  output [7:0] p_level1,
  output [7:0] g_level1
);
  assign p_level1[0] = p[0];
  assign g_level1[0] = g[0];
  
  genvar i;
  generate
    for (i = 1; i < 8; i = i + 1) begin : level1_gen
      assign p_level1[i] = p[i] & p[i-1];
      assign g_level1[i] = g[i] | (p[i] & g[i-1]);
    end
  endgenerate
endmodule

// 第二级前缀计算模块
module prefix_level2_computation (
  input [7:0] p_level1,
  input [7:0] g_level1,
  output [7:0] p_level2,
  output [7:0] g_level2
);
  // 前两位直接传递
  assign p_level2[0] = p_level1[0];
  assign g_level2[0] = g_level1[0];
  assign p_level2[1] = p_level1[1];
  assign g_level2[1] = g_level1[1];
  
  genvar i;
  generate
    for (i = 2; i < 8; i = i + 1) begin : level2_gen
      assign p_level2[i] = p_level1[i] & p_level1[i-2];
      assign g_level2[i] = g_level1[i] | (p_level1[i] & g_level1[i-2]);
    end
  endgenerate
endmodule

// 第三级前缀计算模块
module prefix_level3_computation (
  input [7:0] p_level2,
  input [7:0] g_level2,
  output [7:0] p_level3,
  output [7:0] g_level3
);
  // 前四位直接传递
  assign p_level3[0] = p_level2[0];
  assign g_level3[0] = g_level2[0];
  assign p_level3[1] = p_level2[1];
  assign g_level3[1] = g_level2[1];
  assign p_level3[2] = p_level2[2];
  assign g_level3[2] = g_level2[2];
  assign p_level3[3] = p_level2[3];
  assign g_level3[3] = g_level2[3];
  
  genvar i;
  generate
    for (i = 4; i < 8; i = i + 1) begin : level3_gen
      assign p_level3[i] = p_level2[i] & p_level2[i-4];
      assign g_level3[i] = g_level2[i] | (p_level2[i] & g_level2[i-4]);
    end
  endgenerate
endmodule

// 进位计算模块
module carry_computation (
  input [7:0] g_level3,
  output [7:0] carry
);
  // 计算进位
  assign carry[0] = 1'b0; // 减法无进位输入
  assign carry[1] = g_level3[0];
  assign carry[2] = g_level3[1];
  assign carry[3] = g_level3[2];
  assign carry[4] = g_level3[3];
  assign carry[5] = g_level3[4];
  assign carry[6] = g_level3[5];
  assign carry[7] = g_level3[6];
endmodule