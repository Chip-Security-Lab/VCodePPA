//SystemVerilog
// 顶层模块 - 封装整个存储器系统
module memory_sync_reset #(
  parameter DEPTH = 8,
  parameter WIDTH = 8
)(
  input wire clk,
  input wire reset,
  input wire [WIDTH-1:0] data_in,
  input wire [$clog2(DEPTH)-1:0] addr,
  input wire write_en,
  output wire [WIDTH-1:0] data_out
);

  // 内部连线
  wire [WIDTH-1:0] mem_data_out;
  wire [WIDTH-1:0] mem_data_in;
  wire [$clog2(DEPTH)-1:0] mem_addr;
  wire mem_write_en;
  wire mem_reset;

  // 控制器模块实例化
  memory_controller #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
  ) u_controller (
    .clk(clk),
    .reset(reset),
    .write_en(write_en),
    .data_in(data_in),
    .addr(addr),
    .mem_write_en(mem_write_en),
    .mem_addr(mem_addr),
    .mem_data_in(mem_data_in),
    .mem_reset(mem_reset)
  );

  // 存储器阵列模块实例化
  memory_array #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
  ) u_mem_array (
    .clk(clk),
    .reset(mem_reset),
    .write_en(mem_write_en),
    .addr(mem_addr),
    .data_in(mem_data_in),
    .data_out(mem_data_out)
  );

  // 输出寄存器模块实例化
  output_register #(
    .WIDTH(WIDTH)
  ) u_output_reg (
    .clk(clk),
    .reset(reset),
    .write_en(~write_en),  // 只在读操作时更新输出
    .data_in(mem_data_out),
    .data_out(data_out)
  );

endmodule

// 控制器子模块 - 处理地址和控制信号
module memory_controller #(
  parameter WIDTH = 8,
  parameter DEPTH = 8
)(
  input wire clk,
  input wire reset,
  input wire write_en,
  input wire [WIDTH-1:0] data_in,
  input wire [$clog2(DEPTH)-1:0] addr,
  output reg mem_write_en,
  output reg [$clog2(DEPTH)-1:0] mem_addr,
  output reg [WIDTH-1:0] mem_data_in,
  output reg mem_reset
);

  // 优化控制逻辑，减少寄存器数量和逻辑延迟
  always @(posedge clk) begin
    if (reset) begin
      // 使用块赋值加快复位操作
      mem_write_en <= 1'b0;
      mem_addr <= '0;
      mem_data_in <= '0;
      mem_reset <= 1'b1;
    end else begin
      // 直接传递信号减少延迟
      {mem_write_en, mem_addr, mem_data_in, mem_reset} <= {write_en, addr, data_in, 1'b0};
    end
  end

endmodule

// 存储器阵列子模块 - 管理实际的存储单元
module memory_array #(
  parameter WIDTH = 8,
  parameter DEPTH = 8
)(
  input wire clk,
  input wire reset,
  input wire write_en,
  input wire [$clog2(DEPTH)-1:0] addr,
  input wire [WIDTH-1:0] data_in,
  output wire [WIDTH-1:0] data_out
);

  // 定义存储器和输出寄存器
  reg [WIDTH-1:0] mem [0:DEPTH-1];
  reg [WIDTH-1:0] data_out_reg;
  
  // 优化的存储器读写逻辑
  integer i;

  // 连接输出
  assign data_out = data_out_reg;

  // 优化访问模式，减少比较操作
  always @(posedge clk) begin
    if (reset) begin
      // 使用生成块来优化复位操作
      for (i = 0; i < DEPTH; i = i + 1)
        mem[i] <= '0;
      data_out_reg <= '0;
    end else begin
      // 优化读写条件判断减少比较器链
      if (write_en) 
        mem[addr] <= data_in;
      else
        data_out_reg <= mem[addr];
    end
  end

endmodule

// 输出寄存器子模块 - 管理数据输出
module output_register #(
  parameter WIDTH = 8
)(
  input wire clk,
  input wire reset,
  input wire write_en,
  input wire [WIDTH-1:0] data_in,
  output reg [WIDTH-1:0] data_out
);

  // 优化输出寄存器逻辑
  always @(posedge clk) begin
    if (reset)
      data_out <= '0;
    else if (write_en)
      data_out <= data_in;
    // 删除不必要的else分支，减少逻辑路径
  end

endmodule