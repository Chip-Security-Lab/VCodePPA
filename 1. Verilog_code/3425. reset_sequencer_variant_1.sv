//SystemVerilog
//IEEE 1364-2005 Verilog标准
module reset_sequencer (
  input wire clk,
  input wire global_rst,
  output reg rst_domain1,
  output reg rst_domain2,
  output reg rst_domain3
);
  // Pipeline registers for counter
  reg [3:0] seq_counter;
  reg [3:0] seq_counter_next;
  
  // Comparison result registers
  reg counter_lt_15;
  reg counter_lt_3;
  reg counter_lt_7;
  reg counter_lt_11;
  
  // 计算序列计数器的下一个值
  always @(posedge clk or posedge global_rst) begin
    if (global_rst) begin
      seq_counter <= 4'd0;
      seq_counter_next <= 4'd0;
    end else begin
      seq_counter <= seq_counter_next;
      seq_counter_next <= seq_counter_next + counter_lt_15;
    end
  end
  
  // 计算比较结果
  always @(posedge clk or posedge global_rst) begin
    if (global_rst) begin
      counter_lt_15 <= 1'b1;
      counter_lt_3 <= 1'b1;
      counter_lt_7 <= 1'b1;
      counter_lt_11 <= 1'b1;
    end else begin
      counter_lt_15 <= (seq_counter_next < 4'd15);
      counter_lt_3 <= (seq_counter_next < 4'd3);
      counter_lt_7 <= (seq_counter_next < 4'd7);
      counter_lt_11 <= (seq_counter_next < 4'd11);
    end
  end
  
  // 更新域1复位信号
  always @(posedge clk or posedge global_rst) begin
    if (global_rst) begin
      rst_domain1 <= 1'b1;
    end else begin
      rst_domain1 <= counter_lt_3;
    end
  end
  
  // 更新域2复位信号
  always @(posedge clk or posedge global_rst) begin
    if (global_rst) begin
      rst_domain2 <= 1'b1;
    end else begin
      rst_domain2 <= counter_lt_7;
    end
  end
  
  // 更新域3复位信号
  always @(posedge clk or posedge global_rst) begin
    if (global_rst) begin
      rst_domain3 <= 1'b1;
    end else begin
      rst_domain3 <= counter_lt_11;
    end
  end
endmodule