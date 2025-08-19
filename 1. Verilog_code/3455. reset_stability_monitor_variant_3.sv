//SystemVerilog
//IEEE 1364-2005 Verilog
`timescale 1ns / 1ps
module reset_stability_monitor (
  input  wire clk,
  input  wire reset_n,
  output reg  reset_unstable
);
  
  // 状态记录
  reg reset_prev;
  reg [3:0] stability_quotient; // 使用SRT除法结果作为稳定性指标
  
  // 阈值常量定义
  localparam [3:0] STABILITY_THRESHOLD = 4'd5;
  
  // SRT除法器输入/输出
  wire [3:0] divided_value = 4'hF; // 固定被除数
  wire [3:0] divisor_value;      // 除数基于复位边沿计数
  wire [3:0] quotient;           // 商
  wire [3:0] remainder;          // 余数
  wire       div_done;           // 除法完成标志

  // 动态计算除数值 - 基于复位跳变特性
  reg [3:0] edge_counter;
  
  always @(posedge clk) begin
    // 记录上一个状态
    reset_prev <= reset_n;
    
    // 检测边沿变化
    if (reset_n != reset_prev) begin
      edge_counter <= edge_counter + 4'd1;
    end
    
    // 防止计数器溢出
    if (edge_counter == 4'hF) begin
      edge_counter <= 4'd2; // 保持除数非零
    end
    
    // 更新稳定性指标
    if (div_done) begin
      stability_quotient <= quotient;
    end
    
    // 设置不稳定信号
    reset_unstable <= (stability_quotient >= STABILITY_THRESHOLD) ? 1'b1 : reset_unstable;
  end
  
  // 使除数非零
  assign divisor_value = (edge_counter == 4'd0) ? 4'd1 : edge_counter;
  
  // SRT除法器实例化
  srt_divider_4bit srt_div_inst (
    .clk       (clk),
    .reset_n   (reset_n),
    .dividend  (divided_value),
    .divisor   (divisor_value),
    .start     (reset_n != reset_prev), // 复位边沿变化时启动除法
    .quotient  (quotient),
    .remainder (remainder),
    .done      (div_done)
  );
  
  // 初始值设置（为了仿真兼容性）
  initial begin
    reset_prev = 1'b1;
    edge_counter = 4'd0;
    stability_quotient = 4'd0;
    reset_unstable = 1'b0;
  end
  
endmodule

// SRT除法器实现 - 4位
module srt_divider_4bit (
  input  wire       clk,
  input  wire       reset_n,
  input  wire [3:0] dividend,
  input  wire [3:0] divisor,
  input  wire       start,
  output reg  [3:0] quotient,
  output reg  [3:0] remainder,
  output reg        done
);

  // SRT除法器状态
  localparam IDLE = 2'b00;
  localparam CALC = 2'b01;
  localparam FINALIZE = 2'b10;
  
  reg [1:0] state;
  reg [2:0] step_counter;  // 计数器跟踪SRT算法步骤
  
  // SRT除法的工作寄存器
  reg [7:0] partial_remainder; // 部分余数，扩展为8位
  reg [3:0] divisor_reg;       // 存储除数
  reg [3:0] quotient_reg;      // 存储商
  
  // SRT除法的辅助信号
  wire [4:0] sub_result;      // 减法结果
  wire [4:0] add_result;      // 加法结果
  wire       remainder_msb;   // 部分余数的符号位
  
  // 计算辅助结果
  assign remainder_msb = partial_remainder[7];
  assign sub_result = partial_remainder[7:3] - {1'b0, divisor_reg};
  assign add_result = partial_remainder[7:3] + {1'b0, divisor_reg};

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      done <= 1'b0;
      step_counter <= 3'd0;
      quotient <= 4'd0;
      remainder <= 4'd0;
      partial_remainder <= 8'd0;
      divisor_reg <= 4'd0;
      quotient_reg <= 4'd0;
    end
    else begin
      case (state)
        IDLE: begin
          if (start) begin
            // 初始化SRT除法
            state <= CALC;
            done <= 1'b0;
            step_counter <= 3'd0;
            partial_remainder <= {4'd0, dividend};
            divisor_reg <= divisor;
            quotient_reg <= 4'd0;
          end
        end
        
        CALC: begin
          // SRT除法主循环
          if (step_counter < 3'd4) begin
            // 左移部分余数
            partial_remainder <= partial_remainder << 1;
            
            // 下一步
            step_counter <= step_counter + 3'd1;
          end
          else begin
            // 基于部分余数符号执行SRT步骤
            if (remainder_msb) begin
              // 负部分余数，加除数
              partial_remainder[7:3] <= add_result;
              quotient_reg <= {quotient_reg[2:0], 1'b0};  // 移位并添加0
            end
            else begin
              // 正部分余数，减除数
              partial_remainder[7:3] <= sub_result;
              quotient_reg <= {quotient_reg[2:0], 1'b1};  // 移位并添加1
            end
            
            // 检查是否完成所有位
            if (step_counter >= 3'd7) begin
              state <= FINALIZE;
            end
            else begin
              step_counter <= step_counter + 3'd1;
            end
          end
        end
        
        FINALIZE: begin
          // 处理最终结果
          quotient <= quotient_reg;
          remainder <= partial_remainder[3:0]; // 取余数
          done <= 1'b1;
          state <= IDLE;
        end
        
        default: state <= IDLE;
      endcase
    end
  end
  
endmodule