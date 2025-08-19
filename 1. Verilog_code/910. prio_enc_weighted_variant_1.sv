//SystemVerilog
// 权重比较器子模块
module weight_comparator #(
  parameter WIDTH = 8
)(
  input clk,
  input [WIDTH-1:0] weight_a,
  input [WIDTH-1:0] weight_b,
  input [1:0] idx_a,
  input [1:0] idx_b,
  output reg [WIDTH-1:0] max_weight,
  output reg [1:0] max_idx
);

  always @(posedge clk) begin
    if(weight_a >= weight_b) begin
      max_weight <= weight_a;
      max_idx <= idx_a;
    end else begin
      max_weight <= weight_b;
      max_idx <= idx_b;
    end
  end

endmodule

// 请求处理子模块
module request_processor #(
  parameter N = 4,
  parameter WIDTH = 8
)(
  input clk,
  input [N-1:0] req,
  input [N-1:0] weight,
  output reg [N-1:0] valid_req,
  output reg [WIDTH-1:0] curr_weight [0:N-1]
);

  integer i;
  always @(posedge clk) begin
    for(i=0; i<N; i=i+1) begin
      valid_req[i] <= req[i];
      curr_weight[i] <= req[i] ? weight[i] : 8'b0;
    end
  end

endmodule

// 顶层模块
module prio_enc_weighted #(
  parameter N = 4,
  parameter WIDTH = 8
)(
  input clk,
  input [N-1:0] req,
  input [N-1:0] weight,
  output reg [1:0] max_idx
);

  // 内部信号
  wire [N-1:0] valid_req;
  wire [WIDTH-1:0] curr_weight [0:N-1];
  wire [WIDTH-1:0] stage1_max_weight_01;
  wire [1:0] stage1_max_idx_01;
  wire [WIDTH-1:0] stage1_max_weight_23;
  wire [1:0] stage1_max_idx_23;
  wire [WIDTH-1:0] max_weight;

  // 实例化请求处理模块
  request_processor #(
    .N(N),
    .WIDTH(WIDTH)
  ) req_proc (
    .clk(clk),
    .req(req),
    .weight(weight),
    .valid_req(valid_req),
    .curr_weight(curr_weight)
  );

  // 实例化第一组比较器
  weight_comparator #(
    .WIDTH(WIDTH)
  ) comp_01 (
    .clk(clk),
    .weight_a(curr_weight[0]),
    .weight_b(curr_weight[1]),
    .idx_a(2'd0),
    .idx_b(2'd1),
    .max_weight(stage1_max_weight_01),
    .max_idx(stage1_max_idx_01)
  );

  // 实例化第二组比较器
  weight_comparator #(
    .WIDTH(WIDTH)
  ) comp_23 (
    .clk(clk),
    .weight_a(curr_weight[2]),
    .weight_b(curr_weight[3]),
    .idx_a(2'd2),
    .idx_b(2'd3),
    .max_weight(stage1_max_weight_23),
    .max_idx(stage1_max_idx_23)
  );

  // 实例化最终比较器
  weight_comparator #(
    .WIDTH(WIDTH)
  ) comp_final (
    .clk(clk),
    .weight_a(stage1_max_weight_01),
    .weight_b(stage1_max_weight_23),
    .idx_a(stage1_max_idx_01),
    .idx_b(stage1_max_idx_23),
    .max_weight(max_weight),
    .max_idx(max_idx)
  );

endmodule