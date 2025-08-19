//SystemVerilog
// 顶层模块
module reset_sync_with_ram #(
  parameter ADDR_WIDTH = 2
)(
  input  wire                     clk,
  input  wire                     rst_n,
  output wire                     synced,
  output wire [2**ADDR_WIDTH-1:0] mem_data
);
  
  // 内部连线
  wire reset_synced;
  
  // 实例化复位同步子模块
  reset_synchronizer u_reset_synchronizer (
    .clk      (clk),
    .rst_n    (rst_n),
    .synced   (reset_synced)
  );
  
  // 实例化内存控制子模块
  memory_controller #(
    .ADDR_WIDTH (ADDR_WIDTH)
  ) u_memory_controller (
    .clk       (clk),
    .rst_n     (rst_n),
    .mem_data  (mem_data)
  );
  
  // 将内部同步信号连接到输出
  assign synced = reset_synced;
  
endmodule

// 复位同步器子模块
module reset_synchronizer (
  input  wire  clk,
  input  wire  rst_n,
  output wire  synced
);
  
  // 同步复位信号寄存器
  reg flop;
  
  // 复位同步器逻辑
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      flop <= 1'b0;
    end else begin
      flop <= 1'b1;
    end
  end
  
  // 输出赋值
  assign synced = flop;
  
endmodule

// 内存控制器子模块
module memory_controller #(
  parameter ADDR_WIDTH = 2
)(
  input  wire                     clk,
  input  wire                     rst_n,
  output reg  [2**ADDR_WIDTH-1:0] mem_data
);
  
  // 内存数据控制逻辑
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      mem_data <= {(2**ADDR_WIDTH){1'b0}};
    end else begin
      mem_data <= {(2**ADDR_WIDTH){1'b1}};
    end
  end
  
endmodule