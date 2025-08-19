//SystemVerilog
module reset_status_register (
  input wire clk,
  input wire clear,
  input wire pwr_rst,
  input wire wdt_rst,
  input wire sw_rst,
  input wire ext_rst,
  output reg [7:0] rst_status
);
  // 将复位逻辑拆分为多个流水线级
  reg wdt_rst_stage1, wdt_rst_stage2;
  reg sw_rst_stage1, sw_rst_stage2;
  reg ext_rst_stage1, ext_rst_stage2;
  reg clear_stage1, clear_stage2;
  reg [7:0] rst_status_next;

  // 合并所有具有相同触发条件的always块
  always @(posedge clk or posedge pwr_rst) begin
    if (pwr_rst) begin
      // 第一级流水线复位
      wdt_rst_stage1 <= 1'b0;
      sw_rst_stage1 <= 1'b0;
      ext_rst_stage1 <= 1'b0;
      clear_stage1 <= 1'b0;
      
      // 第二级流水线复位
      wdt_rst_stage2 <= 1'b0;
      sw_rst_stage2 <= 1'b0;
      ext_rst_stage2 <= 1'b0;
      clear_stage2 <= 1'b0;
      
      // 第三级流水线复位
      rst_status_next <= 8'h01;
      
      // 第四级流水线复位
      rst_status <= 8'h01;
    end else begin
      // 第一级流水线 - 捕获输入信号
      wdt_rst_stage1 <= wdt_rst;
      sw_rst_stage1 <= sw_rst;
      ext_rst_stage1 <= ext_rst;
      clear_stage1 <= clear;
      
      // 第二级流水线 - 处理信号
      wdt_rst_stage2 <= wdt_rst_stage1;
      sw_rst_stage2 <= sw_rst_stage1;
      ext_rst_stage2 <= ext_rst_stage1;
      clear_stage2 <= clear_stage1;
      
      // 第三级流水线 - 计算下一个状态值
      if (clear_stage2) begin
        rst_status_next <= 8'h00;
      end else begin
        rst_status_next <= rst_status;
        if (wdt_rst_stage2) rst_status_next[1] <= 1'b1;
        if (sw_rst_stage2) rst_status_next[2] <= 1'b1;
        if (ext_rst_stage2) rst_status_next[3] <= 1'b1;
      end
      
      // 第四级流水线 - 更新输出寄存器
      rst_status <= rst_status_next;
    end
  end
endmodule