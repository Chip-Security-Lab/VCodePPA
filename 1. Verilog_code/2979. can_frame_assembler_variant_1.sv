//SystemVerilog
module can_frame_assembler(
  input wire clk, rst_n,
  input wire [10:0] id,
  input wire [7:0] data [0:7],
  input wire [3:0] dlc,
  input wire rtr, ide, assemble,
  output reg [127:0] frame,
  output reg frame_ready
);
  // 流水线阶段定义
  typedef enum logic [1:0] {
    IDLE  = 2'b00,
    STAGE1 = 2'b01,  // 头部组装
    STAGE2 = 2'b10,  // 数据组装
    STAGE3 = 2'b11   // 完成组装
  } pipeline_state_t;
  
  // 流水线寄存器
  pipeline_state_t pipeline_state;
  reg [10:0] id_stage1, id_stage2;
  reg [3:0] dlc_stage1, dlc_stage2;
  reg rtr_stage1, rtr_stage2;
  reg ide_stage1, ide_stage2;
  reg [7:0] data_stage1 [0:7];
  reg [7:0] data_stage2 [0:7];
  reg [18:0] header_stage2; // 保存SOF和头部信息
  reg valid_stage1, valid_stage2, valid_stage3;
  
  // 流水线控制
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pipeline_state <= IDLE;
      valid_stage1 <= 0;
      valid_stage2 <= 0;
      valid_stage3 <= 0;
      frame_ready <= 0;
    end else begin
      // 使用case语句替代if-else级联
      case (pipeline_state)
        IDLE: begin
          if (assemble) begin
            // 阶段1: 捕获输入并开始头部组装
            id_stage1 <= id;
            dlc_stage1 <= dlc;
            rtr_stage1 <= rtr;
            ide_stage1 <= ide;
            for (int i = 0; i < 8; i++) begin
              data_stage1[i] <= data[i];
            end
            valid_stage1 <= 1;
            pipeline_state <= STAGE1;
          end else begin
            valid_stage1 <= 0;
            frame_ready <= 0;
          end
        end
        
        STAGE1: begin
          // 阶段2: 组装帧头部和准备数据
          // 将阶段1的数据传递到阶段2
          id_stage2 <= id_stage1;
          dlc_stage2 <= dlc_stage1;
          rtr_stage2 <= rtr_stage1;
          ide_stage2 <= ide_stage1;
          
          // 组装帧头部 (SOF + ID + 控制位)
          header_stage2 <= {
            dlc_stage1,      // [18:15] DLC
            1'b0,            // [14] r0 reserved bit
            ide_stage1,      // [13] IDE
            rtr_stage1,      // [12] RTR
            id_stage1,       // [11:1] ID
            1'b0             // [0] SOF
          };
          
          // 传递数据字段
          for (int i = 0; i < 8; i++) begin
            data_stage2[i] <= data_stage1[i];
          end
          
          valid_stage1 <= 0;
          valid_stage2 <= 1;
          pipeline_state <= STAGE2;
        end
        
        STAGE2: begin
          // 阶段3: 最终帧组装
          // 组装完整帧
          frame[18:0] <= header_stage2; // 头部
          
          // 数据字段处理
          if (!rtr_stage2) begin
            frame[82:19] <= {
              data_stage2[0], data_stage2[1], data_stage2[2], data_stage2[3], 
              data_stage2[4], data_stage2[5], data_stage2[6], data_stage2[7]
            };
          end else begin
            frame[82:19] <= 64'h0; // RTR帧无数据
          end
          
          // 清零剩余位
          frame[127:83] <= 0;
          
          valid_stage2 <= 0;
          valid_stage3 <= 1;
          pipeline_state <= STAGE3;
        end
        
        STAGE3: begin
          // 输出控制
          frame_ready <= 1;
          valid_stage3 <= 0;
          pipeline_state <= IDLE; // 准备下一帧
        end
      endcase
    end
  end
endmodule