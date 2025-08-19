//SystemVerilog
module watchdog_reset #(
  parameter TIMEOUT = 1024
) (
  input wire clk,
  input wire watchdog_kick,
  input wire rst_n,
  output reg watchdog_rst
);
  reg [$clog2(TIMEOUT)-1:0] counter_stage1;
  reg [$clog2(TIMEOUT)-1:0] counter_stage2;
  reg [$clog2(TIMEOUT)-1:0] counter_stage3;
  
  reg kick_stage1, kick_stage2;
  reg compare_result_stage1, compare_result_stage2;
  reg increment_stage1, increment_stage2;
  
  // Stage 1: Input registration and condition detection
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter_stage1 <= 0;
      kick_stage1 <= 1'b0;
      increment_stage1 <= 1'b0;
      compare_result_stage1 <= 1'b0;
    end else begin
      counter_stage1 <= counter_stage3;
      kick_stage1 <= watchdog_kick;
      increment_stage1 <= (counter_stage3 < TIMEOUT-1);
      compare_result_stage1 <= (counter_stage3 == TIMEOUT-2);
    end
  end
  
  // Stage 2: Processing logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter_stage2 <= 0;
      kick_stage2 <= 1'b0;
      increment_stage2 <= 1'b0;
      compare_result_stage2 <= 1'b0;
    end else begin
      kick_stage2 <= kick_stage1;
      increment_stage2 <= increment_stage1;
      compare_result_stage2 <= compare_result_stage1;
      
      // 使用case语句替代if-else级联
      case ({kick_stage1, increment_stage1})
        2'b10: counter_stage2 <= 0;                  // 踢狗情况
        2'b01: counter_stage2 <= counter_stage1 + 1; // 计数递增情况
        default: counter_stage2 <= counter_stage1;   // 其他情况保持不变
      endcase
    end
  end
  
  // Stage 3: Final stage counter update and output generation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter_stage3 <= 0;
      watchdog_rst <= 1'b0;
    end else begin
      counter_stage3 <= counter_stage2;
      watchdog_rst <= compare_result_stage2;
    end
  end
endmodule