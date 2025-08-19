//SystemVerilog
`timescale 1ns / 1ps

module dual_clock_reset_sync (
  input  wire clk_a,    // 时钟A
  input  wire clk_b,    // 时钟B
  input  wire reset_in, // 异步复位输入
  output wire reset_a,  // 同步到clk_a的复位输出
  output wire reset_b   // 同步到clk_b的复位输出
);
  // 双FF同步器用于时钟域A的复位信号同步
  (* ASYNC_REG = "TRUE" *) reg [1:0] sync_a_ff;
  
  // 双FF同步器用于时钟域B的复位信号同步
  (* ASYNC_REG = "TRUE" *) reg [1:0] sync_b_ff;
  
  // 复位信号输出寄存器
  reg reset_a_reg;
  reg reset_b_reg;
  
  // 时钟域A的第一级同步器
  always @(posedge clk_a or posedge reset_in) begin
    if (reset_in) begin
      sync_a_ff[0] <= 1'b1;
    end else begin
      sync_a_ff[0] <= 1'b0;
    end
  end
  
  // 时钟域A的第二级同步器
  always @(posedge clk_a or posedge reset_in) begin
    if (reset_in) begin
      sync_a_ff[1] <= 1'b1;
    end else begin
      sync_a_ff[1] <= sync_a_ff[0];
    end
  end
  
  // 时钟域A的复位输出寄存器
  always @(posedge clk_a or posedge reset_in) begin
    if (reset_in) begin
      reset_a_reg <= 1'b1;
    end else begin
      reset_a_reg <= sync_a_ff[1];
    end
  end
  
  // 时钟域B的第一级同步器
  always @(posedge clk_b or posedge reset_in) begin
    if (reset_in) begin
      sync_b_ff[0] <= 1'b1;
    end else begin
      sync_b_ff[0] <= 1'b0;
    end
  end
  
  // 时钟域B的第二级同步器
  always @(posedge clk_b or posedge reset_in) begin
    if (reset_in) begin
      sync_b_ff[1] <= 1'b1;
    end else begin
      sync_b_ff[1] <= sync_b_ff[0];
    end
  end
  
  // 时钟域B的复位输出寄存器
  always @(posedge clk_b or posedge reset_in) begin
    if (reset_in) begin
      reset_b_reg <= 1'b1;
    end else begin
      reset_b_reg <= sync_b_ff[1];
    end
  end
  
  // 输出赋值
  assign reset_a = reset_a_reg;
  assign reset_b = reset_b_reg;
  
endmodule