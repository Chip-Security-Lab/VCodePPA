//SystemVerilog
module moore_4state_shift_ctrl #(parameter COUNT_WIDTH = 4)(
  input  clk,
  input  rst,
  input  start,
  input  [COUNT_WIDTH-1:0] shift_count,
  output reg shift_en,
  output reg done,
  // 新增流水线控制信号
  input  ready_in,
  output reg valid_out,
  output reg ready_out
);
  // 状态编码优化，使用one-hot编码减少译码逻辑
  localparam WAIT    = 4'b0001,
             LOAD    = 4'b0010,
             SHIFT   = 4'b0100,
             DONE_ST = 4'b1000;
             
  // 流水线阶段寄存器
  reg [3:0] state_stage1, next_state_stage1;
  reg [3:0] state_stage2, next_state_stage2;
  reg [COUNT_WIDTH-1:0] counter_stage1, next_counter_stage1;
  reg [COUNT_WIDTH-1:0] counter_stage2, next_counter_stage2;
  
  // 流水线控制信号
  reg valid_stage1, valid_stage2;
  reg counter_is_zero_stage1, counter_is_zero_stage2;
  reg shift_en_stage1, shift_en_stage2;
  reg done_stage1, done_stage2;
  
  // 第一级流水线：状态更新和计数器更新
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1   <= WAIT;
      counter_stage1 <= 0;
      valid_stage1   <= 1'b0;
    end else if (ready_out || !valid_stage1) begin
      state_stage1   <= next_state_stage1;
      counter_stage1 <= next_counter_stage1;
      valid_stage1   <= start || (state_stage1 != WAIT);
    end
  end

  // 第二级流水线：输出计算
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage2   <= WAIT;
      counter_stage2 <= 0;
      valid_stage2   <= 1'b0;
      shift_en       <= 1'b0;
      done           <= 1'b0;
      valid_out      <= 1'b0;
    end else if (ready_in || !valid_stage2) begin
      state_stage2   <= state_stage1;
      counter_stage2 <= counter_stage1;
      valid_stage2   <= valid_stage1;
      shift_en       <= shift_en_stage1;
      done           <= done_stage1;
      valid_out      <= valid_stage1;
    end
  end
  
  // 流水线阶段间的反压控制
  always @* begin
    ready_out = ready_in || !valid_stage2;
  end

  // 第一级流水线组合逻辑：状态控制和计数器更新
  always @* begin
    // 默认保持当前值
    next_counter_stage1 = counter_stage1;
    next_state_stage1 = state_stage1;
    counter_is_zero_stage1 = (counter_stage1 == 0);
    
    case (1'b1) 
      state_stage1[0]: begin // WAIT
        if (start && ready_out) next_state_stage1 = LOAD;
      end
      
      state_stage1[1]: begin // LOAD
        next_counter_stage1 = shift_count;
        next_state_stage1 = SHIFT;
      end
      
      state_stage1[2]: begin // SHIFT
        if (counter_is_zero_stage1) begin
          next_state_stage1 = DONE_ST;
        end else begin
          next_counter_stage1 = counter_stage1 - 1'b1;
        end
      end
      
      state_stage1[3]: begin // DONE_ST
        next_state_stage1 = WAIT;
      end
    endcase
  end
  
  // 第二级流水线组合逻辑：输出控制
  always @* begin
    // 默认输出值
    shift_en_stage1 = 1'b0;
    done_stage1 = 1'b0;
    counter_is_zero_stage2 = (counter_stage2 == 0);
    
    case (1'b1)
      state_stage1[2]: begin // SHIFT
        shift_en_stage1 = 1'b1;
      end
      
      state_stage1[3]: begin // DONE_ST
        done_stage1 = 1'b1;
      end
    endcase
  end
  
  // 流水线完成信号生成
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      next_counter_stage2 <= 0;
      next_state_stage2 <= WAIT;
    end else begin
      next_counter_stage2 <= next_counter_stage1;
      next_state_stage2 <= next_state_stage1;
    end
  end
endmodule