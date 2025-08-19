//SystemVerilog
module fifo_arbiter(
  input clk, rst_n,
  input [3:0] request,
  input new_req,
  output reg [3:0] grant,
  output empty
);
  reg [3:0] fifo [0:3];  // Simple FIFO to store requests
  reg [1:0] wr_ptr, rd_ptr;
  
  // 简化empty信号计算
  assign empty = (wr_ptr == rd_ptr);
  
  // 优化后的写指针加法器 - 直接实现+1逻辑，减少关键路径
  wire [1:0] next_wr_ptr = wr_ptr + 2'b01;
  
  // 优化后的读指针加法器 - 直接实现+1逻辑，减少关键路径
  wire [1:0] next_rd_ptr = rd_ptr + 2'b01;
  
  // 写操作分离出更新逻辑
  wire wr_update = new_req;
  
  // 读操作分离出更新逻辑
  wire rd_update = !empty;
  
  // 预先计算下一个指针值，减少组合逻辑延迟
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 2'b00;
      rd_ptr <= 2'b00;
      grant <= 4'b0000;
    end 
    else begin
      // 写操作逻辑
      if (wr_update) begin
        fifo[wr_ptr] <= request;
        wr_ptr <= next_wr_ptr;
      end
      
      // 读操作逻辑
      if (rd_update) begin
        grant <= fifo[rd_ptr];
        rd_ptr <= next_rd_ptr;
      end 
      else begin
        grant <= 4'b0000;
      end
    end
  end
endmodule