//SystemVerilog
module mixed_sync_async_intr_ctrl(
  input clk, rst_n,
  input [7:0] async_intr,
  input [7:0] sync_intr,
  output reg [3:0] intr_id,
  output reg intr_out
);
  reg [7:0] async_intr_sync1, async_intr_sync2;
  wire [7:0] sync_masked, async_masked;
  reg [7:0] async_mask, sync_mask;
  reg async_priority;
  
  // Double-flop synchronizer for async inputs
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      async_intr_sync1 <= 8'h0;
      async_intr_sync2 <= 8'h0;
    end else begin
      async_intr_sync1 <= async_intr;
      async_intr_sync2 <= async_intr_sync1;
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
  
  assign async_masked = async_intr_sync2 & async_mask;
  assign sync_masked = sync_intr & sync_mask;
  
  // Pipelined detection logic - Stage 1
  reg async_active_stage1, sync_active_stage1;
  reg [7:0] async_masked_reg, sync_masked_reg;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      async_active_stage1 <= 1'b0;
      sync_active_stage1 <= 1'b0;
      async_masked_reg <= 8'h0;
      sync_masked_reg <= 8'h0;
    end else begin
      async_active_stage1 <= |async_masked;
      sync_active_stage1 <= |sync_masked;
      async_masked_reg <= async_masked;
      sync_masked_reg <= sync_masked;
    end
  end
  
  // Priority encoder pipeline registers
  reg [2:0] async_id_stage1, async_id_stage2;
  reg [2:0] sync_id_stage1, sync_id_stage2;
  
  // First half of priority encoder for async interrupts - split logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      async_id_stage1 <= 3'b0;
    end else begin
      async_id_stage1[2] <= async_masked[7] | async_masked[6] | async_masked[5] | async_masked[4];
      async_id_stage1[1] <= async_masked[7] | async_masked[6] | 
                           (~async_masked[5] & ~async_masked[4] & (async_masked[3] | async_masked[2]));
      async_id_stage1[0] <= async_masked[7] | (~async_masked[6] & async_masked[5]);
    end
  end
  
  // Second half of priority encoder for async interrupts
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      async_id_stage2 <= 3'b0;
    end else begin
      async_id_stage2 <= async_id_stage1 | {
        1'b0,
        1'b0,
        (~async_masked_reg[6] & ~async_masked_reg[4] & async_masked_reg[3]) | 
        (~async_masked_reg[6] & ~async_masked_reg[4] & ~async_masked_reg[2] & async_masked_reg[1])
      };
    end
  end
  
  // First half of priority encoder for sync interrupts
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_id_stage1 <= 3'b0;
    end else begin
      sync_id_stage1[2] <= sync_masked[7] | sync_masked[6] | sync_masked[5] | sync_masked[4];
      sync_id_stage1[1] <= sync_masked[7] | sync_masked[6] | 
                         (~sync_masked[5] & ~sync_masked[4] & (sync_masked[3] | sync_masked[2]));
      sync_id_stage1[0] <= sync_masked[7] | (~sync_masked[6] & sync_masked[5]);
    end
  end
  
  // Second half of priority encoder for sync interrupts
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_id_stage2 <= 3'b0;
    end else begin
      sync_id_stage2 <= sync_id_stage1 | {
        1'b0,
        1'b0,
        (~sync_masked_reg[6] & ~sync_masked_reg[4] & sync_masked_reg[3]) | 
        (~sync_masked_reg[6] & ~sync_masked_reg[4] & ~sync_masked_reg[2] & sync_masked_reg[1])
      };
    end
  end
  
  // Pipeline register for async_priority
  reg async_priority_reg;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      async_priority_reg <= 1'b1;
    end else begin
      async_priority_reg <= async_priority;
    end
  end
  
  // Final output selection logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_out <= 1'b0;
      intr_id <= 4'd0;
    end else begin
      if (async_active_stage1 && (async_priority_reg || !sync_active_stage1)) begin
        intr_out <= 1'b1;
        intr_id <= {1'b1, async_id_stage2};
      end else if (sync_active_stage1) begin
        intr_out <= 1'b1;
        intr_id <= {1'b0, sync_id_stage2};
      end else begin
        intr_out <= 1'b0;
        intr_id <= 4'd0;
      end
    end
  end
endmodule