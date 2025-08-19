//SystemVerilog
module moore_3state_pipeline #(parameter WIDTH = 8)(
  input  clk,
  input  rst,
  input  valid_in,
  input  [WIDTH-1:0] data_in,
  output reg [WIDTH-1:0] data_out,
  output reg valid_out
);

  // 流水线控制信号
  reg valid_stage0, valid_stage1, valid_stage2;
  // 流水线数据寄存器
  reg [WIDTH-1:0] data_stage0, data_stage1, data_stage2;

  // 流水线第一阶段 - 输入数据捕获
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      valid_stage0 <= 1'b0;
    end else begin
      valid_stage0 <= valid_in;
    end
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      data_stage0 <= {WIDTH{1'b0}};
    end else if (valid_in) begin
      data_stage0 <= data_in;
    end
  end

  // 流水线第二阶段 - 中间处理
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      valid_stage1 <= 1'b0;
    end else begin
      valid_stage1 <= valid_stage0;
    end
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      data_stage1 <= {WIDTH{1'b0}};
    end else if (valid_stage0) begin
      data_stage1 <= data_stage0;
    end
  end

  // 流水线第三阶段 - 输出结果
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      valid_stage2 <= 1'b0;
    end else begin
      valid_stage2 <= valid_stage1;
    end
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      data_stage2 <= {WIDTH{1'b0}};
    end else if (valid_stage1) begin
      data_stage2 <= data_stage1;
    end
  end

  // 输出寄存器
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      valid_out <= 1'b0;
    end else begin
      valid_out <= valid_stage2;
    end
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      data_out <= {WIDTH{1'b0}};
    end else if (valid_stage2) begin
      data_out <= data_stage2;
    end
  end

endmodule