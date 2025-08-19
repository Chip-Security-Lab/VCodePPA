//SystemVerilog
// 顶层模块 - 将功能分解为子模块
module prio_enc_latch_sync #(parameter BITS=6)(
  input clk, latch_en, rst,
  input [BITS-1:0] din,
  output [$clog2(BITS)-1:0] enc_addr
);
  // 内部信号定义
  wire [BITS-1:0] latched_data;
  
  // 子模块实例化 - 数据锁存器
  data_latch #(
    .WIDTH(BITS)
  ) latch_inst (
    .clk(clk),
    .rst(rst),
    .latch_en(latch_en),
    .din(din),
    .latched_data(latched_data)
  );
  
  // 子模块实例化 - 优先编码器
  priority_encoder #(
    .BITS(BITS)
  ) encoder_inst (
    .clk(clk),
    .rst(rst),
    .din(latched_data),
    .enc_addr(enc_addr)
  );
  
endmodule

// 子模块 - 数据锁存器
module data_latch #(parameter WIDTH=6)(
  input clk, rst, latch_en,
  input [WIDTH-1:0] din,
  output reg [WIDTH-1:0] latched_data
);
  
  always @(posedge clk) begin
    if (rst) begin
      latched_data <= {WIDTH{1'b0}};
    end
    else if (latch_en) begin
      latched_data <= din;
    end
  end
  
endmodule

// 子模块 - 优先编码器
module priority_encoder #(parameter BITS=6)(
  input clk, rst,
  input [BITS-1:0] din,
  output reg [$clog2(BITS)-1:0] enc_addr
);
  
  integer i;
  
  always @(posedge clk) begin
    if (rst) begin
      enc_addr <= {$clog2(BITS){1'b0}};
    end
    else begin
      enc_addr <= {$clog2(BITS){1'b0}}; // 默认值
      // 优先编码逻辑 - 优化了循环实现
      for (i = BITS-1; i >= 0; i = i-1) begin
        if (din[i]) begin
          enc_addr <= i[$clog2(BITS)-1:0];
          // 一旦找到最高优先级的位，可以提前结束循环
          // 综合工具通常会正确处理此类优化
        end
      end
    end
  end
  
endmodule