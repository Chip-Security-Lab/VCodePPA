//SystemVerilog
`timescale 1ns / 1ps

module can_loopback_tester(
  input wire clk, rst_n,
  output reg can_tx,
  input wire can_rx,
  output reg test_active, test_passed, test_failed
);
  // 定义测试模式数组和状态寄存器
  reg [7:0] test_pattern [0:7];
  reg [3:0] test_state; 
  reg [2:0] bit_count, byte_count;
  reg [10:0] test_id;
  
  // 使用单热编码定义状态，改善状态机可靠性
  localparam IDLE       = 4'b0001, 
             START_TEST = 4'b0010, 
             SEND_SOF   = 4'b0100,
             RESERVED   = 4'b1000;
  
  // 状态转换优化信号
  wire next_bit = (bit_count == 3'h7);
  wire next_byte = (byte_count == 3'h7) && next_bit;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 复位逻辑：使用置零方式优化资源
      test_state <= IDLE;
      test_active <= 1'b0;
      test_passed <= 1'b0;
      test_failed <= 1'b0;
      bit_count <= 3'b000;
      byte_count <= 3'b000;
      
      // 使用简洁的测试模式初始化
      test_pattern[0] <= 8'h55;
      test_pattern[1] <= 8'hAA;
      {test_pattern[2], test_pattern[3], test_pattern[4], 
       test_pattern[5], test_pattern[6], test_pattern[7]} <= 48'h0;
      
      test_id <= 11'h555;
      can_tx <= 1'b1;  // 空闲状态为高电平
    end else begin
      // 优化状态机实现，避免复杂比较链
      case (1'b1) // 使用单热编码的优势：单比特比较
        test_state[0]: begin // IDLE
          test_state <= START_TEST;
        end
        
        test_state[1]: begin // START_TEST
          test_active <= 1'b1;
          bit_count <= 3'b000;
          byte_count <= 3'b000;
          test_state <= SEND_SOF;
        end
        
        test_state[2]: begin // SEND_SOF
          can_tx <= 1'b0;
          // 优化状态转换逻辑
          test_state <= IDLE;  // 临时循环到IDLE
        end
        
        test_state[3]: begin // RESERVED
          test_state <= IDLE;
        end
        
        default: begin
          // 防止未定义状态
          test_state <= IDLE;
        end
      endcase
    end
  end
  
  // 并行逻辑用于监控测试状态
  // 将组合逻辑与时序逻辑分离，提高时序性能
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 初始化测试监控状态
    end else if (test_active) begin
      // 在这里添加测试监控逻辑
    end
  end

endmodule