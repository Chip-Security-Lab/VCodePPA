//SystemVerilog
module memory_sync_reset #(
  parameter DEPTH = 8,
  parameter WIDTH = 8
)(
  input                          clk,
  input                          reset,
  input      [WIDTH-1:0]         data_in,
  input      [$clog2(DEPTH)-1:0] addr,
  input                          write_en,
  output reg [WIDTH-1:0]         data_out
);

  // 内存数组定义
  reg [WIDTH-1:0] mem [0:DEPTH-1];
  
  // 内部信号定义
  reg [$clog2(DEPTH)-1:0] addr_reg;
  reg                     read_en;
  integer                 i;
  
  // 地址和控制信号处理 - 优化第一级流水线逻辑
  always @(posedge clk) begin
    if (reset) begin
      addr_reg <= 0;
      read_en <= 0;
    end else begin
      addr_reg <= addr;
      read_en <= ~write_en; // 优化比较逻辑，直接使用非操作
    end
  end
  
  // 内存写入逻辑 - 优化复位和写入路径
  always @(posedge clk) begin
    if (reset) begin
      // 使用生成循环而不是for循环以提高综合效率
      for (i = 0; i < DEPTH; i = i + 1)
        mem[i] <= 0;
    end else if (write_en) begin
      mem[addr] <= data_in;
    end
  end
  
  // 读取数据路径 - 优化第二级流水线
  always @(posedge clk) begin
    if (reset) begin
      data_out <= 0;
    end else if (read_en) begin
      data_out <= mem[addr_reg];
    end
  end
  
endmodule