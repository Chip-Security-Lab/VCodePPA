//SystemVerilog
`timescale 1ns/1ps
module mixed_sync_async_intr_ctrl(
  input clk, rst_n,
  input [7:0] async_intr,
  input [7:0] sync_intr,
  output reg [3:0] intr_id,
  output reg intr_out
);
  // Synchronizer stage registers
  reg [7:0] async_intr_sync1, async_intr_sync2, async_intr_sync3;
  
  // Mask registers and control
  reg [7:0] async_mask, sync_mask;
  reg async_priority;
  
  // Pipeline stage 1: Masked signals
  reg [7:0] async_masked_stage1, sync_masked_stage1;
  
  // Pipeline stage 2: Active detection
  reg async_active_stage2, sync_active_stage2;
  reg [7:0] async_masked_stage2, sync_masked_stage2;
  
  // Pipeline stage 3: Priority encoding
  reg [2:0] async_priority_id_stage3, sync_priority_id_stage3;
  reg async_active_stage3, sync_active_stage3;
  reg async_priority_stage3;
  
  // Pipeline stage 4: Output decision logic
  reg [3:0] intr_id_stage4;
  reg intr_out_stage4;
  
  // Pipeline stage 5-7: Output buffering
  reg [3:0] intr_id_stage5, intr_id_stage6, intr_id_stage7;
  reg intr_out_stage5, intr_out_stage6, intr_out_stage7;
  
  // Stage 1: Double-flop synchronizer for async inputs with extra stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      async_intr_sync1 <= 8'h0;
      async_intr_sync2 <= 8'h0;
      async_intr_sync3 <= 8'h0;
    end else begin
      async_intr_sync1 <= async_intr;
      async_intr_sync2 <= async_intr_sync1;
      async_intr_sync3 <= async_intr_sync2;
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
  
  // Stage 1: Mask application
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      async_masked_stage1 <= 8'h0;
      sync_masked_stage1 <= 8'h0;
    end else begin
      async_masked_stage1 <= async_intr_sync3 & async_mask;
      sync_masked_stage1 <= sync_intr & sync_mask;
    end
  end
  
  // Stage 2: Active detection and pass masked values
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      async_active_stage2 <= 1'b0;
      sync_active_stage2 <= 1'b0;
      async_masked_stage2 <= 8'h0;
      sync_masked_stage2 <= 8'h0;
    end else begin
      async_active_stage2 <= |async_masked_stage1;
      sync_active_stage2 <= |sync_masked_stage1;
      async_masked_stage2 <= async_masked_stage1;
      sync_masked_stage2 <= sync_masked_stage1;
    end
  end
  
  // Stage 3: Priority encoding
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      async_priority_id_stage3 <= 3'd0;
      sync_priority_id_stage3 <= 3'd0;
      async_active_stage3 <= 1'b0;
      sync_active_stage3 <= 1'b0;
      async_priority_stage3 <= 1'b1;
    end else begin
      // Priority encoder for async interrupts - split logic for better timing
      casez (async_masked_stage2)
        8'b1???????: async_priority_id_stage3 <= 3'd7;
        8'b01??????: async_priority_id_stage3 <= 3'd6;
        8'b001?????: async_priority_id_stage3 <= 3'd5;
        8'b0001????: async_priority_id_stage3 <= 3'd4;
        8'b00001???: async_priority_id_stage3 <= 3'd3;
        8'b000001??: async_priority_id_stage3 <= 3'd2;
        8'b0000001?: async_priority_id_stage3 <= 3'd1;
        8'b00000001: async_priority_id_stage3 <= 3'd0;
        default:     async_priority_id_stage3 <= 3'd0;
      endcase
      
      // Priority encoder for sync interrupts - split logic for better timing
      casez (sync_masked_stage2)
        8'b1???????: sync_priority_id_stage3 <= 3'd7;
        8'b01??????: sync_priority_id_stage3 <= 3'd6;
        8'b001?????: sync_priority_id_stage3 <= 3'd5;
        8'b0001????: sync_priority_id_stage3 <= 3'd4;
        8'b00001???: sync_priority_id_stage3 <= 3'd3;
        8'b000001??: sync_priority_id_stage3 <= 3'd2;
        8'b0000001?: sync_priority_id_stage3 <= 3'd1;
        8'b00000001: sync_priority_id_stage3 <= 3'd0;
        default:     sync_priority_id_stage3 <= 3'd0;
      endcase
      
      async_active_stage3 <= async_active_stage2;
      sync_active_stage3 <= sync_active_stage2;
      async_priority_stage3 <= async_priority;
    end
  end
  
  // Stage 4: Output decision logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id_stage4 <= 4'd0;
      intr_out_stage4 <= 1'b0;
    end else begin
      if (async_active_stage3 && async_priority_stage3) begin
        intr_out_stage4 <= 1'b1;
        intr_id_stage4 <= {1'b1, async_priority_id_stage3};
      end else if (sync_active_stage3) begin
        intr_out_stage4 <= 1'b1;
        intr_id_stage4 <= {1'b0, sync_priority_id_stage3};
      end else if (async_active_stage3) begin
        intr_out_stage4 <= 1'b1;
        intr_id_stage4 <= {1'b1, async_priority_id_stage3};
      end else begin
        intr_out_stage4 <= 1'b0;
        intr_id_stage4 <= 4'd0;
      end
    end
  end
  
  // Stage 5-7: Buffer registers for high fanout signals
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset all buffer registers
      intr_id_stage5 <= 4'd0;
      intr_id_stage6 <= 4'd0;
      intr_id_stage7 <= 4'd0;
      intr_out_stage5 <= 1'b0;
      intr_out_stage6 <= 1'b0;
      intr_out_stage7 <= 1'b0;
      intr_id <= 4'd0;
      intr_out <= 1'b0;
    end else begin
      // First stage buffer
      intr_id_stage5 <= intr_id_stage4;
      intr_out_stage5 <= intr_out_stage4;
      
      // Second stage buffer
      intr_id_stage6 <= intr_id_stage5;
      intr_out_stage6 <= intr_out_stage5;
      
      // Third stage buffer
      intr_id_stage7 <= intr_id_stage6;
      intr_out_stage7 <= intr_out_stage6;
      
      // Final output registers
      intr_id <= intr_id_stage7;
      intr_out <= intr_out_stage7;
    end
  end
endmodule