//SystemVerilog
//IEEE 1364-2005
module reset_controller(
  input clk, master_rst_n, power_stable,
  output reg core_rst_n, periph_rst_n, io_rst_n
);
  reg [1:0] rst_state;
  
  always @(posedge clk or negedge master_rst_n) begin
    if (!master_rst_n) begin
      rst_state <= 2'b00;
      core_rst_n <= 1'b0;
      periph_rst_n <= 1'b0;
      io_rst_n <= 1'b0;
    end else if (power_stable) begin
      case (rst_state)
        2'b00: begin 
          reset_sequence_step(core_rst_n, rst_state, 2'b01); 
        end
        2'b01: begin 
          reset_sequence_step(periph_rst_n, rst_state, 2'b10); 
        end
        2'b10: begin 
          reset_sequence_step(io_rst_n, rst_state, 2'b11); 
        end
        2'b11: rst_state <= 2'b11;
      endcase
    end
  end
  
  // 任务：处理顺序复位步骤
  task reset_sequence_step;
    inout reg rst_signal;         // 当前步骤要释放的复位信号
    inout reg [1:0] state;        // 状态寄存器
    input [1:0] next_state;       // 下一状态值
    begin
      rst_signal <= 1'b1;         // 释放复位（高电平有效）
      state <= next_state;        // 更新到下一状态
    end
  endtask
endmodule