//SystemVerilog
//-----------------------------------------------------------------------------
// 顶层模块：时钟域转换奇偶校验模块
//-----------------------------------------------------------------------------
module cdc_parity_module(
  input        src_clk,    // 源时钟域时钟
  input        dst_clk,    // 目标时钟域时钟
  input        src_rst_n,  // 源时钟域复位信号（低电平有效）
  input  [7:0] src_data,   // 源时钟域输入数据
  output       dst_parity  // 目标时钟域奇偶校验结果
);
  // 内部信号声明
  wire src_parity_bit;  // 源时钟域的奇偶校验位

  // 实例化源时钟域奇偶校验计算子模块
  parity_generator u_parity_generator (
    .clk      (src_clk),
    .rst_n    (src_rst_n),
    .data_in  (src_data),
    .parity   (src_parity_bit)
  );

  // 实例化时钟域转换子模块
  sync_bridge #(
    .DATA_WIDTH (1)
  ) u_sync_bridge (
    .dst_clk    (dst_clk),
    .data_in    (src_parity_bit),
    .data_out   (dst_parity)
  );

endmodule

//-----------------------------------------------------------------------------
// 子模块：奇偶校验生成器
//-----------------------------------------------------------------------------
module parity_generator(
  input             clk,     // 时钟信号
  input             rst_n,   // 复位信号（低电平有效）
  input      [7:0]  data_in, // 输入数据
  output reg        parity   // 奇偶校验输出
);
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      parity <= 1'b0;
    else
      parity <= ^data_in;  // 计算偶校验位
  end
  
endmodule

//-----------------------------------------------------------------------------
// 子模块：同步桥接器
//-----------------------------------------------------------------------------
module sync_bridge #(
  parameter DATA_WIDTH = 1  // 可参数化数据宽度
)(
  input                    dst_clk,  // 目标时钟域时钟
  input  [DATA_WIDTH-1:0]  data_in,  // 输入数据
  output [DATA_WIDTH-1:0]  data_out  // 同步后的输出数据
);
  
  // 同步寄存器链，采用二级触发器同步以减少亚稳态风险
  reg [DATA_WIDTH-1:0] sync_reg1;
  reg [DATA_WIDTH-1:0] sync_reg2;
  
  always @(posedge dst_clk) begin
    sync_reg1 <= data_in;     // 第一级触发器
    sync_reg2 <= sync_reg1;   // 第二级触发器
  end
  
  // 输出赋值
  assign data_out = sync_reg2;
  
endmodule