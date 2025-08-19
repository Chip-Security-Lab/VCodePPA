//SystemVerilog
module mixed_sync_async_intr_ctrl(
  input clk, rst_n,
  input [7:0] async_intr,
  input [7:0] sync_intr,
  output reg [3:0] intr_id,
  output reg intr_out
);
  // 将异步中断输入直接寄存，不再做中间同步化处理
  reg [7:0] async_intr_reg;
  reg [7:0] async_intr_sync;
  reg [7:0] sync_intr_reg;
  wire [7:0] sync_masked, async_masked;
  reg [7:0] async_mask, sync_mask;
  reg async_priority;
  
  // 直接寄存异步输入和同步输入，将寄存器前移
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      async_intr_reg <= 8'h0;
      sync_intr_reg <= 8'h0;
    end else begin
      async_intr_reg <= async_intr;
      sync_intr_reg <= sync_intr;
    end
  end
  
  // 同步化异步中断信号的第二级
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      async_intr_sync <= 8'h0;
    end else begin
      async_intr_sync <= async_intr_reg;
    end
  end
  
  // Mask registers
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      async_mask <= 8'hFF;
      sync_mask <= 8'hFF;
      async_priority <= 1'b1; // Default: async has priority
    end else begin
      // Mask registers would be updated via config interface (not shown)
    end
  end
  
  // 掩码操作移到寄存器后
  assign async_masked = async_intr_sync & async_mask;
  assign sync_masked = sync_intr_reg & sync_mask;
  
  // 优化编码函数使用case语句提高综合效率
  function [2:0] encode_priority;
    input [7:0] intr_vector;
    begin
      casez (intr_vector)
        8'b1???????: encode_priority = 3'd7;
        8'b01??????: encode_priority = 3'd6;
        8'b001?????: encode_priority = 3'd5;
        8'b0001????: encode_priority = 3'd4;
        8'b00001???: encode_priority = 3'd3;
        8'b000001??: encode_priority = 3'd2;
        8'b0000001?: encode_priority = 3'd1;
        8'b00000001: encode_priority = 3'd0;
        default:     encode_priority = 3'd0;
      endcase
    end
  endfunction
  
  // 优化中断逻辑，增加寄存器以进行流水线处理
  reg any_async, any_sync;
  reg [2:0] async_priority_id, sync_priority_id;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      any_async <= 1'b0;
      any_sync <= 1'b0;
      async_priority_id <= 3'd0;
      sync_priority_id <= 3'd0;
    end else begin
      any_async <= |async_masked;
      any_sync <= |sync_masked;
      async_priority_id <= encode_priority(async_masked);
      sync_priority_id <= encode_priority(sync_masked);
    end
  end
  
  // 最终输出逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_out <= 1'b0;
      intr_id <= 4'd0;
    end else begin
      // Default values
      intr_out <= any_async || any_sync;
      
      if (any_async && (async_priority || !any_sync)) begin
        intr_id <= {1'b1, async_priority_id};  // Async ID base (8)
      end else if (any_sync) begin
        intr_id <= {1'b0, sync_priority_id};   // Sync ID base (0)
      end else begin
        intr_id <= 4'd0;
      end
    end
  end
endmodule