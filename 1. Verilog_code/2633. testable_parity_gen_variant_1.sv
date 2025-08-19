//SystemVerilog
module testable_parity_gen(
  input wire clk,         // 时钟信号
  input wire rst_n,       // 复位信号
  input wire [7:0] data,  // 输入数据
  input wire test_mode,   // 测试模式选择
  input wire test_parity, // 测试奇偶校验位输入
  input wire req,         // 请求信号，替代原始的valid
  output reg ack,         // 应答信号，替代原始的ready
  output reg parity_bit   // 奇偶校验位输出
);

  // 内部信号定义
  reg [7:0] data_reg;       // 数据寄存器
  reg test_mode_reg;        // 测试模式寄存器
  reg test_parity_reg;      // 测试奇偶校验位寄存器
  reg req_reg;              // 请求寄存器
  reg processing;           // 处理状态标志
  reg [1:0] state;          // 状态机
  
  // 状态定义
  localparam IDLE = 2'b00;
  localparam STAGE1 = 2'b01;
  localparam STAGE2 = 2'b10;
  localparam STAGE3 = 2'b11;

  // 状态机实现
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      ack <= 1'b0;
      processing <= 1'b0;
      data_reg <= 8'b0;
      test_mode_reg <= 1'b0;
      test_parity_reg <= 1'b0;
      req_reg <= 1'b0;
    end else begin
      req_reg <= req;
      
      case(state)
        IDLE: begin
          ack <= 1'b0;
          if (req && !req_reg) begin  // 上升沿检测
            // 捕获输入数据
            data_reg <= data;
            test_mode_reg <= test_mode;
            test_parity_reg <= test_parity;
            processing <= 1'b1;
            state <= STAGE1;
          end
        end
        
        STAGE1: begin
          // 计算奇偶校验
          processing <= 1'b1;
          state <= STAGE2;
        end
        
        STAGE2: begin
          // 完成处理，输出结果
          processing <= 1'b0;
          ack <= 1'b1;  // 发送应答信号
          state <= STAGE3;
        end
        
        STAGE3: begin
          if (!req) begin  // 等待请求信号撤销
            ack <= 1'b0;
            state <= IDLE;
          end
        end
      endcase
    end
  end
  
  // 数据流水线第二级 - 奇偶校验位计算
  reg computed_parity;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      computed_parity <= 1'b0;
    end else if (state == STAGE1) begin
      computed_parity <= ^data_reg;
    end
  end
  
  // 数据流水线第三级 - 输出选择与寄存
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      parity_bit <= 1'b0;
    end else if (state == STAGE2) begin
      parity_bit <= test_mode_reg ? test_parity_reg : computed_parity;
    end
  end

endmodule