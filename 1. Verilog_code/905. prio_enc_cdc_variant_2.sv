//SystemVerilog
//IEEE 1364-2005
module prio_enc_cdc #(parameter DW=16)(
  input clkA, clkB, rst,
  input [DW-1:0] data_in,
  output [$clog2(DW)-1:0] sync_out
);

  wire [DW-1:0] synchronized_data;
  
  // 实例化时钟域转换子模块
  cdc_synchronizer #(
    .DATA_WIDTH(DW)
  ) synchronizer_inst (
    .clk_src(clkA),
    .clk_dst(clkB),
    .data_in(data_in),
    .data_out(synchronized_data)
  );
  
  // 实例化优先级编码器子模块
  priority_encoder #(
    .WIDTH(DW)
  ) encoder_inst (
    .clk(clkB),
    .rst(rst),
    .data_in(synchronized_data),
    .encoded_out(sync_out)
  );

endmodule

//IEEE 1364-2005
module cdc_synchronizer #(
  parameter DATA_WIDTH = 16
)(
  input clk_src, clk_dst,
  input [DATA_WIDTH-1:0] data_in,
  output reg [DATA_WIDTH-1:0] data_out
);

  // 双寄存器同步器设计
  reg [DATA_WIDTH-1:0] sync_reg1;
  
  // 第一级同步 - 捕获源时钟域数据
  always @(posedge clk_src) begin
    sync_reg1 <= data_in;
  end
  
  // 第二级同步 - 将数据传输到目标时钟域
  always @(posedge clk_dst) begin
    data_out <= sync_reg1;
  end

endmodule

//IEEE 1364-2005
module priority_encoder #(
  parameter WIDTH = 16
)(
  input clk, rst,
  input [WIDTH-1:0] data_in,
  output reg [$clog2(WIDTH)-1:0] encoded_out
);

  // 内部优先级编码结果寄存器
  reg [$clog2(WIDTH)-1:0] priority_value;
  integer i;
  
  // 优先级编码逻辑
  always @(posedge clk) begin
    if (rst) begin
      priority_value <= 0;
    end
    else begin
      priority_value <= 0;
      for (i = 0; i < WIDTH; i = i+1) begin
        if (data_in[i]) priority_value <= i[$clog2(WIDTH)-1:0];
      end
    end
  end
  
  // 输出寄存数据
  always @(posedge clk) begin
    if (rst) begin
      encoded_out <= 0;
    end
    else begin
      encoded_out <= priority_value;
    end
  end

endmodule