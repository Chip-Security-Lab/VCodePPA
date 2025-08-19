//SystemVerilog
module prio_enc_pipe_stage #(parameter W=32, parameter A=5)(
  input clk, rst,
  input [W-1:0] req,
  output reg [A-1:0] addr_reg
);
  reg [A-1:0] addr_comb;
  
  // 组合逻辑部分 - 使用casez实现优先编码器
  always @(*) begin
    // 默认值
    addr_comb = 0;
    
    casez(req)
      // 从最低位开始检查，按优先级顺序排列
      {{(W-1){1'b?}}, 1'b1}: addr_comb = 0;
      {{(W-2){1'b?}}, 1'b1, 1'b0}: addr_comb = 1;
      {{(W-3){1'b?}}, 1'b1, 2'b0}: addr_comb = 2;
      {{(W-4){1'b?}}, 1'b1, 3'b0}: addr_comb = 3;
      {{(W-5){1'b?}}, 1'b1, 4'b0}: addr_comb = 4;
      {{(W-6){1'b?}}, 1'b1, 5'b0}: addr_comb = 5;
      {{(W-7){1'b?}}, 1'b1, 6'b0}: addr_comb = 6;
      {{(W-8){1'b?}}, 1'b1, 7'b0}: addr_comb = 7;
      // 处理范围8-15
      {{(W-9){1'b?}}, 1'b1, 8'b0}: addr_comb = 8;
      {{(W-10){1'b?}}, 1'b1, 9'b0}: addr_comb = 9;
      {{(W-11){1'b?}}, 1'b1, 10'b0}: addr_comb = 10;
      {{(W-12){1'b?}}, 1'b1, 11'b0}: addr_comb = 11;
      {{(W-13){1'b?}}, 1'b1, 12'b0}: addr_comb = 12;
      {{(W-14){1'b?}}, 1'b1, 13'b0}: addr_comb = 13;
      {{(W-15){1'b?}}, 1'b1, 14'b0}: addr_comb = 14;
      {{(W-16){1'b?}}, 1'b1, 15'b0}: addr_comb = 15;
      // 处理范围16-23
      {{(W-17){1'b?}}, 1'b1, 16'b0}: addr_comb = 16;
      {{(W-18){1'b?}}, 1'b1, 17'b0}: addr_comb = 17;
      {{(W-19){1'b?}}, 1'b1, 18'b0}: addr_comb = 18;
      {{(W-20){1'b?}}, 1'b1, 19'b0}: addr_comb = 19;
      {{(W-21){1'b?}}, 1'b1, 20'b0}: addr_comb = 20;
      {{(W-22){1'b?}}, 1'b1, 21'b0}: addr_comb = 21;
      {{(W-23){1'b?}}, 1'b1, 22'b0}: addr_comb = 22;
      {{(W-24){1'b?}}, 1'b1, 23'b0}: addr_comb = 23;
      // 处理范围24-31（假设W=32）
      {{(W-25){1'b?}}, 1'b1, 24'b0}: addr_comb = 24;
      {{(W-26){1'b?}}, 1'b1, 25'b0}: addr_comb = 25;
      {{(W-27){1'b?}}, 1'b1, 26'b0}: addr_comb = 26;
      {{(W-28){1'b?}}, 1'b1, 27'b0}: addr_comb = 27;
      {{(W-29){1'b?}}, 1'b1, 28'b0}: addr_comb = 28;
      {{(W-30){1'b?}}, 1'b1, 29'b0}: addr_comb = 29;
      {{(W-31){1'b?}}, 1'b1, 30'b0}: addr_comb = 30;
      {1'b1, {(W-1){1'b0}}}: addr_comb = 31;
      default: addr_comb = 0; // 所有位都为0时的默认情况
    endcase
  end
  
  // 寄存器部分 - 重新定位到组合逻辑之前
  always @(posedge clk) begin
    if (rst) begin
      addr_reg <= 0;
    end
    else begin
      addr_reg <= addr_comb;
    end
  end
  
  // 指定IEEE 1364-2005 Verilog标准
  /* synthesis ieee_std_1364_2005 */
endmodule