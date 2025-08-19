//SystemVerilog
// 顶层模块
module RD10 #(
  parameter BITS = 8,
  parameter PIPELINE_STAGES = 3
)(
  input  logic                clk,
  input  logic                rst,
  input  logic                en,
  input  logic [BITS-1:0]     in_val,
  output logic [BITS-1:0]     out_val
);

  // 内部连接信号
  logic [BITS-1:0] stage1_to_stage2_data;
  logic            stage1_to_stage2_valid;
  
  logic [BITS-1:0] stage2_to_stage3_data;
  logic            stage2_to_stage3_valid;

  // 实例化第一级流水线子模块
  pipeline_stage_1 #(
    .BITS(BITS)
  ) u_stage1 (
    .clk          (clk),
    .rst          (rst),
    .en           (en),
    .in_val       (in_val),
    .out_data     (stage1_to_stage2_data),
    .out_valid    (stage1_to_stage2_valid)
  );

  // 实例化第二级流水线子模块
  pipeline_stage_2 #(
    .BITS(BITS)
  ) u_stage2 (
    .clk          (clk),
    .rst          (rst),
    .in_valid     (stage1_to_stage2_valid),
    .in_data      (stage1_to_stage2_data),
    .out_data     (stage2_to_stage3_data),
    .out_valid    (stage2_to_stage3_valid)
  );

  // 实例化输出级流水线子模块
  pipeline_stage_3 #(
    .BITS(BITS)
  ) u_stage3 (
    .clk          (clk),
    .rst          (rst),
    .in_valid     (stage2_to_stage3_valid),
    .in_data      (stage2_to_stage3_data),
    .out_val      (out_val)
  );

endmodule : RD10

// 第一级流水线子模块
module pipeline_stage_1 #(
  parameter BITS = 8
)(
  input  logic                clk,
  input  logic                rst,
  input  logic                en,
  input  logic [BITS-1:0]     in_val,
  output logic [BITS-1:0]     out_data,
  output logic                out_valid
);

  always_ff @(posedge clk) begin
    if (rst) begin
      out_data  <= '0;
      out_valid <= 1'b0;
    end else begin
      out_data  <= en ? in_val : '0;
      out_valid <= en;
    end
  end

endmodule : pipeline_stage_1

// 第二级流水线子模块
module pipeline_stage_2 #(
  parameter BITS = 8
)(
  input  logic                clk,
  input  logic                rst,
  input  logic                in_valid,
  input  logic [BITS-1:0]     in_data,
  output logic [BITS-1:0]     out_data,
  output logic                out_valid
);

  always_ff @(posedge clk) begin
    if (rst) begin
      out_data  <= '0;
      out_valid <= 1'b0;
    end else begin
      out_data  <= in_valid ? in_data : '0;
      out_valid <= in_valid;
    end
  end

endmodule : pipeline_stage_2

// 第三级流水线(输出级)子模块
module pipeline_stage_3 #(
  parameter BITS = 8
)(
  input  logic                clk,
  input  logic                rst,
  input  logic                in_valid,
  input  logic [BITS-1:0]     in_data,
  output logic [BITS-1:0]     out_val
);

  always_ff @(posedge clk) begin
    if (rst) begin
      out_val <= '0;
    end else begin
      out_val <= in_valid ? in_data : '0;
    end
  end

endmodule : pipeline_stage_3