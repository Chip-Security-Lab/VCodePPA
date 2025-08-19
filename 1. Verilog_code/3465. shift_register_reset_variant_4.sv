//SystemVerilog
module shift_register_reset #(parameter WIDTH = 16)(
  input wire clk,
  input wire reset,
  input wire shift_en,
  input wire data_in,
  output wire [WIDTH-1:0] shift_data
);

  // 将移位寄存器拆分为多个流水线级
  // 每个级别处理WIDTH/4位
  localparam STAGE_SIZE = WIDTH/4;
  
  // 流水线级的数据寄存器
  reg [STAGE_SIZE-1:0] stage1_data;
  reg [STAGE_SIZE-1:0] stage2_data;
  reg [STAGE_SIZE-1:0] stage3_data;
  reg [STAGE_SIZE-1:0] stage4_data;
  
  // 流水线控制信号
  reg stage1_valid, stage2_valid, stage3_valid, stage4_valid;
  
  // 合并所有流水线逻辑到单个always块
  always @(posedge clk) begin
    if (reset) begin
      // 重置所有流水线寄存器
      stage1_data <= {STAGE_SIZE{1'b0}};
      stage2_data <= {STAGE_SIZE{1'b0}};
      stage3_data <= {STAGE_SIZE{1'b0}};
      stage4_data <= {STAGE_SIZE{1'b0}};
      stage1_valid <= 1'b0;
      stage2_valid <= 1'b0;
      stage3_valid <= 1'b0;
      stage4_valid <= 1'b0;
    end
    else begin
      // 第一级流水线 - 始终在shift_en时接收输入数据
      if (shift_en) begin
        stage1_data <= {stage1_data[STAGE_SIZE-2:0], data_in};
        stage1_valid <= 1'b1;
        
        // 第二级流水线 - 当上一级有效且shift_en有效时移位
        if (stage1_valid) begin
          stage2_data <= {stage2_data[STAGE_SIZE-2:0], stage1_data[STAGE_SIZE-1]};
          stage2_valid <= stage1_valid;
          
          // 第三级流水线 - 当上一级有效且shift_en有效时移位
          if (stage2_valid) begin
            stage3_data <= {stage3_data[STAGE_SIZE-2:0], stage2_data[STAGE_SIZE-1]};
            stage3_valid <= stage2_valid;
            
            // 第四级流水线 - 当上一级有效且shift_en有效时移位
            if (stage3_valid) begin
              stage4_data <= {stage4_data[STAGE_SIZE-2:0], stage3_data[STAGE_SIZE-1]};
              stage4_valid <= stage3_valid;
            end
          end
        end
      end
    end
  end
  
  // 输出组合
  assign shift_data = {stage4_data, stage3_data, stage2_data, stage1_data};

endmodule