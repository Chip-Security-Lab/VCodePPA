//SystemVerilog
// 顶层模块 - 协调控制子模块的工作
module can_bit_stuffer (
  input  wire clk,             // 系统时钟
  input  wire rst_n,           // 低电平有效复位
  input  wire data_in,         // 输入数据位
  input  wire data_valid,      // 输入数据有效标志
  input  wire stuffing_active, // 位填充功能使能
  output wire data_out,        // 输出数据位
  output wire data_out_valid,  // 输出数据有效标志
  output wire stuff_error      // 位填充错误指示
);

  // 内部连线和接口信号
  wire data_in_sync;
  wire data_valid_sync;
  wire stuffing_active_sync;
  wire [2:0] bit_count; 
  wire same_bit_detected;
  wire needs_stuffing;
  wire stuff_bit_value;

  // 输入同步子模块实例
  can_input_synchronizer input_sync_inst (
    .clk                (clk),
    .rst_n              (rst_n),
    .data_in            (data_in),
    .data_valid         (data_valid),
    .stuffing_active    (stuffing_active),
    .data_in_sync       (data_in_sync),
    .data_valid_sync    (data_valid_sync),
    .stuffing_active_sync(stuffing_active_sync)
  );

  // 位计数子模块实例
  can_bit_counter counter_inst (
    .clk              (clk),
    .rst_n            (rst_n),
    .data_in          (data_in_sync),
    .data_valid       (data_valid_sync),
    .stuffing_active  (stuffing_active_sync),
    .bit_count        (bit_count),
    .same_bit_detected(same_bit_detected),
    .needs_stuffing   (needs_stuffing)
  );

  // 位填充决策子模块实例
  can_stuff_decision decision_inst (
    .data_in        (data_in_sync),
    .stuff_bit_value(stuff_bit_value)
  );

  // 输出生成子模块实例
  can_output_generator output_inst (
    .clk            (clk),
    .rst_n          (rst_n),
    .data_in        (data_in_sync),
    .data_valid     (data_valid_sync),
    .stuffing_active(stuffing_active_sync),
    .needs_stuffing (needs_stuffing),
    .stuff_bit_value(stuff_bit_value),
    .data_out       (data_out),
    .data_out_valid (data_out_valid),
    .stuff_error    (stuff_error)
  );

endmodule

// 输入同步子模块 - 减少输入延迟并同步外部信号
module can_input_synchronizer (
  input  wire clk,
  input  wire rst_n,
  input  wire data_in,
  input  wire data_valid,
  input  wire stuffing_active,
  output reg  data_in_sync,
  output reg  data_valid_sync,
  output reg  stuffing_active_sync
);

  // 双寄存器同步，减少亚稳态风险
  reg data_in_meta, data_valid_meta, stuffing_active_meta;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 复位所有寄存器
      data_in_meta <= 1'b0;
      data_valid_meta <= 1'b0;
      stuffing_active_meta <= 1'b0;
      data_in_sync <= 1'b0;
      data_valid_sync <= 1'b0;
      stuffing_active_sync <= 1'b0;
    end else begin
      // 首级同步
      data_in_meta <= data_in;
      data_valid_meta <= data_valid;
      stuffing_active_meta <= stuffing_active;
      
      // 次级同步
      data_in_sync <= data_in_meta;
      data_valid_sync <= data_valid_meta;
      stuffing_active_sync <= stuffing_active_meta;
    end
  end
  
endmodule

// 位计数子模块 - 跟踪连续相同位的数量
module can_bit_counter (
  input  wire clk,
  input  wire rst_n,
  input  wire data_in,
  input  wire data_valid,
  input  wire stuffing_active,
  output reg  [2:0] bit_count,
  output reg  same_bit_detected,
  output reg  needs_stuffing
);

  reg last_bit;
  
  // 位计数和状态检测逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_count <= 3'd0;
      last_bit <= 1'b0;
      same_bit_detected <= 1'b0;
      needs_stuffing <= 1'b0;
    end else begin
      // 相同位检测逻辑
      same_bit_detected <= (data_in == last_bit) && data_valid && stuffing_active;
      
      // 填充需求检测逻辑
      needs_stuffing <= (bit_count == 3'd4) && (data_in == last_bit) && data_valid && stuffing_active;
      
      // 位计数逻辑 - 优化计数路径
      if (data_valid && stuffing_active) begin
        if (data_in == last_bit) begin
          if (bit_count == 3'd4) begin
            // 需要填充，重置计数器
            bit_count <= 3'd0;
          end else begin
            // 增加计数器
            bit_count <= bit_count + 3'd1;
          end
        end else begin
          // 位发生变化，重置计数器
          bit_count <= 3'd1; // 从1开始，因为当前位已经计数
          last_bit <= data_in;
        end
      end
    end
  end

endmodule

// 位填充决策子模块 - 决定填充位的值
module can_stuff_decision (
  input  wire data_in,
  output wire stuff_bit_value
);

  // 填充位总是输入位的反码
  assign stuff_bit_value = ~data_in;

endmodule

// 输出生成子模块 - 生成最终输出数据流
module can_output_generator (
  input  wire clk,
  input  wire rst_n,
  input  wire data_in,
  input  wire data_valid,
  input  wire stuffing_active,
  input  wire needs_stuffing,
  input  wire stuff_bit_value,
  output reg  data_out,
  output reg  data_out_valid,
  output reg  stuff_error
);

  // 状态机参数定义
  localparam STATE_IDLE = 2'b00;
  localparam STATE_NORMAL = 2'b01;
  localparam STATE_STUFFING = 2'b10;
  localparam STATE_ERROR = 2'b11;
  
  // 状态寄存器
  reg [1:0] current_state, next_state;
  reg needs_stuffing_reg;
  reg stuff_bit_value_reg;
  
  // 状态寄存及控制信号缓存
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_state <= STATE_IDLE;
      needs_stuffing_reg <= 1'b0;
      stuff_bit_value_reg <= 1'b0;
    end else begin
      current_state <= next_state;
      needs_stuffing_reg <= needs_stuffing;
      stuff_bit_value_reg <= stuff_bit_value;
    end
  end

  // 状态转换逻辑
  always @(*) begin
    case (current_state)
      STATE_IDLE: begin
        if (data_valid && stuffing_active)
          next_state = needs_stuffing_reg ? STATE_STUFFING : STATE_NORMAL;
        else
          next_state = STATE_IDLE;
      end
      
      STATE_NORMAL: begin
        if (!data_valid)
          next_state = STATE_IDLE;
        else if (needs_stuffing_reg)
          next_state = STATE_STUFFING;
        else
          next_state = STATE_NORMAL;
      end
      
      STATE_STUFFING: begin
        next_state = STATE_NORMAL;
      end
      
      STATE_ERROR: begin
        next_state = STATE_IDLE;
      end
      
      default: next_state = STATE_IDLE;
    endcase
  end

  // 输出逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out <= 1'b1;
      data_out_valid <= 1'b0;
      stuff_error <= 1'b0;
    end else begin
      data_out_valid <= 1'b0;
      stuff_error <= 1'b0;
      
      case (current_state)
        STATE_IDLE: begin
          data_out_valid <= 1'b0;
        end
        
        STATE_NORMAL: begin
          if (data_valid && stuffing_active) begin
            data_out <= data_in;
            data_out_valid <= 1'b1;
          end
        end
        
        STATE_STUFFING: begin
          data_out <= stuff_bit_value_reg;
          data_out_valid <= 1'b1;
        end
        
        STATE_ERROR: begin
          stuff_error <= 1'b1;
          data_out_valid <= 1'b0;
        end
      endcase
    end
  end

endmodule