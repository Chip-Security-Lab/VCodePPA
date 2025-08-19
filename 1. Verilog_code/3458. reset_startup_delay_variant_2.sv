//SystemVerilog
module reset_startup_delay (
  input  wire       clk,
  input  wire       reset_n,
  
  // Valid-Ready interface signals
  output reg        valid,
  input  wire       ready,
  output reg  [7:0] data_out,
  
  output reg        system_ready
);
  reg [7:0] delay_counter;
  reg       counter_reached_max;
  
  localparam [7:0] MAX_COUNT = 8'hFF;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      delay_counter <= 8'h00;
      system_ready <= 1'b0;
      valid <= 1'b0;
      counter_reached_max <= 1'b0;
      data_out <= 8'h00;
    end else begin
      // 使用单一比较操作进行范围检查
      if (!counter_reached_max) begin
        // 计数器尚未达到最大值
        if (delay_counter == MAX_COUNT) begin
          // 计数器刚好达到最大值
          counter_reached_max <= 1'b1;
          system_ready <= 1'b1;
          valid <= 1'b1;
          data_out <= delay_counter;
        end else begin
          // 计数器递增
          delay_counter <= delay_counter + 1'b1;
        end
      end else begin
        // 计数器已达到最大值，处理valid/ready握手
        if (valid && ready) begin
          // 数据传输完成，撤销valid信号
          valid <= 1'b0;
        end else if (!valid) begin
          // 准备下一次数据传输
          valid <= 1'b1;
          data_out <= delay_counter;
        end
      end
    end
  end
endmodule