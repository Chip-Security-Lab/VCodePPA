//SystemVerilog
module reset_sync_with_ram #(parameter ADDR_WIDTH = 2) (
  input  wire                     clk,
  input  wire                     rst_n,
  input  wire                     valid_in,    // 输入有效信号
  output wire                     ready_in,    // 输入就绪信号
  output wire                     valid_out,   // 输出有效信号
  input  wire                     ready_out,   // 输出就绪信号
  output wire                     synced,
  output wire [2**ADDR_WIDTH-1:0] mem_data
);
  // Stage 1 registers
  reg                     valid_stage1;
  reg                     flop_stage1;
  reg [2**ADDR_WIDTH-1:0] mem_data_stage1; // 移动到第一阶段
  
  // Stage 2 registers
  reg                     valid_stage2;
  reg                     flop_stage2;
  
  // Pipeline control signals
  wire stage1_ready;
  wire stage2_ready;
  
  // Backpressure handling
  assign stage2_ready = !valid_stage2 || ready_out;
  assign stage1_ready = !valid_stage1 || stage2_ready;
  assign ready_in = stage1_ready;
  
  // Stage 1: Initial synchronization
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      valid_stage1 <= 1'b0;
      flop_stage1  <= 1'b0;
      mem_data_stage1 <= {(2**ADDR_WIDTH){1'b0}}; // 复位时初始化
    end else if(stage1_ready) begin
      valid_stage1 <= valid_in;
      flop_stage1  <= 1'b1;
      mem_data_stage1 <= {(2**ADDR_WIDTH){1'b1}}; // 提前计算内存数据
    end
  end
  
  // Stage 2: 寄存器重定时，移除了内存数据计算
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      valid_stage2 <= 1'b0;
      flop_stage2  <= 1'b0;
    end else if(stage2_ready) begin
      valid_stage2 <= valid_stage1;
      flop_stage2  <= flop_stage1;
    end
  end
  
  // Output assignments
  assign valid_out = valid_stage2;
  assign synced = flop_stage2;
  assign mem_data = mem_data_stage1; // 直接使用第一阶段的内存数据，避免额外延迟
  
endmodule