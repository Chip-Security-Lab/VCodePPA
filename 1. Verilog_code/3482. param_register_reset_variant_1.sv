//SystemVerilog
module param_register_reset #(
  parameter WIDTH = 16,
  parameter RESET_VALUE = 16'hFFFF,
  parameter PIPELINE_STAGES = 3  // 流水线级数
)(
  input                  clk,        // 系统时钟
  input                  rst_n,      // 低电平有效复位
  input                  load,       // 数据加载使能信号
  input  [WIDTH-1:0]     data_in,    // 输入数据总线
  output [WIDTH-1:0]     data_out    // 输出数据总线
);

  // 定义流水线数据通路结构
  reg [WIDTH-1:0]         pipeline_data [0:PIPELINE_STAGES-1];  // 数据流水线寄存器组
  reg [PIPELINE_STAGES-1:0] pipeline_valid;                    // 流水线有效状态跟踪

  // =========================================================================
  // 第一级流水线 - 输入接口阶段
  // =========================================================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 复位状态初始化
      pipeline_data[0] <= RESET_VALUE;
      pipeline_valid[0] <= 1'b0;
    end
    else begin
      if (load) begin
        // 加载新数据到流水线首级
        pipeline_data[0] <= data_in;
        pipeline_valid[0] <= 1'b1;
      end
      else begin
        // 未加载新数据时标记为无效
        pipeline_valid[0] <= 1'b0;
        // 保持当前值不变
      end
    end
  end

  // =========================================================================
  // 中间流水线级 - 数据传播阶段
  // =========================================================================
  genvar i;
  generate
    for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin : g_pipeline_stage
      // 每个流水线级的数据传递逻辑
      always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          // 复位状态初始化
          pipeline_data[i] <= RESET_VALUE;
          pipeline_valid[i] <= 1'b0;
        end
        else begin
          if (pipeline_valid[i-1]) begin
            // 有效数据向下传递
            pipeline_data[i] <= pipeline_data[i-1];
            pipeline_valid[i] <= 1'b1;
          end
          else begin
            // 无效状态传递
            pipeline_valid[i] <= 1'b0;
            // 数据值保持不变
          end
        end
      end
    end
  endgenerate

  // =========================================================================
  // 输出阶段 - 最终数据输出
  // =========================================================================
  // 将最后一级流水线寄存器连接到输出端口
  assign data_out = pipeline_data[PIPELINE_STAGES-1];

endmodule