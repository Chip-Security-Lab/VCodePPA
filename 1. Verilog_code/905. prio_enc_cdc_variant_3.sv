//SystemVerilog
// IEEE 1364-2005 Verilog
module prio_enc_cdc #(parameter DW=16)(
  input clkA, clkB, rst,
  input [DW-1:0] data_in,
  output reg [$clog2(DW)-1:0] sync_out
);
  reg [DW-1:0] sync_reg1;
  reg [$clog2(DW)-1:0] encoded_out;
  
  // Pipeline registers for breaking long combinational paths
  reg [DW-1:0] pipe_data_high, pipe_data_low;
  reg [$clog2(DW)-1:0] pipe_encoded_high, pipe_encoded_low;
  reg pipe_found_high, pipe_found_low;
  
  localparam MID_POINT = DW/2;
  
  // 第一级时钟域同步
  always @(posedge clkA) begin
    sync_reg1 <= data_in;
  end
  
  // 优先编码器逻辑分段实现 - 第一阶段：将数据划分为高低两部分
  always @(posedge clkA) begin
    pipe_data_high <= sync_reg1[DW-1:MID_POINT];
    pipe_data_low <= sync_reg1[MID_POINT-1:0];
  end
  
  // 优先编码器逻辑分段实现 - 第二阶段：分别处理高低两部分
  always @(posedge clkA) begin
    // 处理高位部分
    pipe_found_high <= |pipe_data_high;
    pipe_encoded_high <= 0;
    for(integer i = MID_POINT; i < DW; i = i+1) begin
      if(pipe_data_high[i-MID_POINT]) 
        pipe_encoded_high <= i[$clog2(DW)-1:0];
    end
    
    // 处理低位部分
    pipe_found_low <= |pipe_data_low;
    pipe_encoded_low <= 0;
    for(integer i = 0; i < MID_POINT; i = i+1) begin
      if(pipe_data_low[i]) 
        pipe_encoded_low <= i[$clog2(DW)-1:0];
    end
  end
  
  // 优先编码器逻辑分段实现 - 第三阶段：合并结果
  always @(posedge clkA) begin
    encoded_out <= pipe_found_high ? pipe_encoded_high : 
                  (pipe_found_low ? pipe_encoded_low : {$clog2(DW){1'b0}});
  end
  
  // 第二级时钟域同步和复位逻辑
  always @(posedge clkB) begin
    if(rst) sync_out <= 0;
    else sync_out <= encoded_out;
  end
endmodule