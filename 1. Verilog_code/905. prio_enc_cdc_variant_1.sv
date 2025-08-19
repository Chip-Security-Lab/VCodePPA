//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// IEEE 1364-2005 Verilog
// File: prio_enc_cdc.v
// 
// 顶层模块：实现跨时钟域的优先编码器功能
///////////////////////////////////////////////////////////////////////////////
module prio_enc_cdc #(parameter DW=16)(
  input clkA, clkB, rst,
  input [DW-1:0] data_in,
  output [$clog2(DW)-1:0] sync_out
);

  // 内部信号定义
  wire [DW-1:0] synchronized_data;

  // 子模块实例化：时钟域同步器
  clock_domain_sync #(
    .DATA_WIDTH(DW)
  ) sync_unit (
    .clkA(clkA),
    .clkB(clkB),
    .data_in(data_in),
    .sync_data_out(synchronized_data)
  );

  // 子模块实例化：优先编码器
  priority_encoder #(
    .DW(DW)
  ) encoder_unit (
    .clkB(clkB),
    .rst(rst),
    .data_in(synchronized_data),
    .encoded_out(sync_out)
  );

endmodule

///////////////////////////////////////////////////////////////////////////////
// 子模块：时钟域同步器
// 功能：使用两级同步器将数据从clkA时钟域安全传输到clkB时钟域
///////////////////////////////////////////////////////////////////////////////
module clock_domain_sync #(
  parameter DATA_WIDTH = 16
)(
  input clkA, clkB,
  input [DATA_WIDTH-1:0] data_in,
  output reg [DATA_WIDTH-1:0] sync_data_out
);

  // 第一级寄存器（源时钟域）
  reg [DATA_WIDTH-1:0] sync_reg1;
  
  // 时钟域同步逻辑
  always @(posedge clkA) begin
    sync_reg1 <= data_in;
  end
  
  // 第二级寄存器（目标时钟域）
  always @(posedge clkB) begin
    sync_data_out <= sync_reg1;
  end

endmodule

///////////////////////////////////////////////////////////////////////////////
// 子模块：优先编码器
// 功能：对输入数据进行优先编码处理，输出最高优先级位的索引
///////////////////////////////////////////////////////////////////////////////
module priority_encoder #(
  parameter DW = 16
)(
  input clkB, rst,
  input [DW-1:0] data_in,
  output reg [$clog2(DW)-1:0] encoded_out
);

  // 内部变量
  integer i;

  // 优先编码逻辑
  always @(posedge clkB) begin
    if(rst) begin
      encoded_out <= 0;
    end else begin
      encoded_out <= 0; // 默认值
      
      // 扫描寻找最高优先级的位
      for(i=0; i<DW; i=i+1) begin
        if(data_in[i]) begin
          encoded_out <= i[$clog2(DW)-1:0];
        end
      end
    end
  end

endmodule