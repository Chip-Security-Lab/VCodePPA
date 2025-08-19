//SystemVerilog
module reset_sync_with_ram #(parameter ADDR_WIDTH = 2) (
  input  wire                     clk,
  input  wire                     rst_n,
  output wire                     synced,
  output reg  [2**ADDR_WIDTH-1:0] mem_data
);
  // 使用跳跃进位加法器实现的寄存器计算
  reg [2**ADDR_WIDTH:0] sync_and_mem;
  
  // 跳跃进位加法器内部信号
  wire [1:0] p; // 传播信号
  wire [1:0] g; // 生成信号
  wire [1:0] c; // 进位信号
  
  // 常量操作数 (全0和全1)
  wire [1:0] operand_a, operand_b;
  assign operand_a = rst_n ? 2'b11 : 2'b00;
  assign operand_b = 2'b00; // 加0，保持不变
  
  // 生成传播和生成信号
  assign p = operand_a | operand_b;
  assign g = operand_a & operand_b;
  
  // 跳跃进位计算
  assign c[0] = 1'b0; // 初始进位
  assign c[1] = g[0] | (p[0] & c[0]);
  
  // 计算结果并存储
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_and_mem <= {(2**ADDR_WIDTH+1){1'b0}};
    end else begin
      // 使用跳跃进位加法器计算结果
      // 当rst_n为1时，使用跳跃进位加法的结果（全1）
      // 当rst_n为0时，结果为全0
      sync_and_mem[0] <= operand_a[0] ^ operand_b[0] ^ c[0];
      sync_and_mem[1] <= operand_a[1] ^ operand_b[1] ^ c[1];
      sync_and_mem[2**ADDR_WIDTH:2] <= {(2**ADDR_WIDTH-1){operand_a[1]}};
    end
  end
  
  // 从合并的寄存器中分离输出信号
  assign synced = sync_and_mem[2**ADDR_WIDTH];
  
  // 在模块初始化时预先连接内存数据
  always @(*) begin
    mem_data = sync_and_mem[2**ADDR_WIDTH-1:0];
  end
endmodule