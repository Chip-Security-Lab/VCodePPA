//SystemVerilog
// IEEE 1364-2005 Verilog标准
module prio_enc_fsm #(parameter WIDTH=6)(
  input clk, rst,
  input [WIDTH-1:0] in,
  output reg [$clog2(WIDTH)-1:0] addr
);
  // 使用参数化的位宽
  localparam IDLE = 1'b0;
  localparam SCAN = 1'b1;
  reg state;
  
  // 实例化优先编码器子模块
  prio_encoder #(.WIDTH(WIDTH)) encoder_inst(
    .in(in),
    .addr(encoder_addr)
  );
  
  wire [$clog2(WIDTH)-1:0] encoder_addr;
  
  // FSM控制逻辑
  always @(posedge clk) begin
    if(rst) begin
      state <= IDLE;
      addr <= 0;
    end else if(state == IDLE && |in) begin
      state <= SCAN;
      addr <= 0;
    end else if(state == IDLE && ~|in) begin
      state <= IDLE;
    end else if(state == SCAN) begin
      state <= IDLE;
      addr <= encoder_addr; // 使用子模块的输出
    end else begin
      state <= IDLE;
    end
  end
endmodule

// 可复用的优先编码器子模块
module prio_encoder #(parameter WIDTH=6)(
  input [WIDTH-1:0] in,
  output reg [$clog2(WIDTH)-1:0] addr
);
  integer i;
  
  always @(*) begin
    addr = 0; // 默认值
    for(i=0; i<WIDTH; i=i+1)
      if(in[i]) addr = i[$clog2(WIDTH)-1:0];
  end
endmodule