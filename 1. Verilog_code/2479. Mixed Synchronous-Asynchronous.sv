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
  
  // Priority logic (combinational)
  always @(*) begin
    if (|async_masked && async_priority) begin
      intr_out = 1'b1;
      intr_id = {1'b1, 3'b000}; // Start with async ID base (8)
      casez (async_masked)
        8'b1???????: intr_id[2:0] = 3'd7;
        8'b01??????: intr_id[2:0] = 3'd6;
        8'b001?????: intr_id[2:0] = 3'd5;
        8'b0001????: intr_id[2:0] = 3'd4;
        8'b00001???: intr_id[2:0] = 3'd3;
        8'b000001??: intr_id[2:0] = 3'd2;
        8'b0000001?: intr_id[2:0] = 3'd1;
        8'b00000001: intr_id[2:0] = 3'd0;
      endcase
    end else if (|sync_masked) begin
      intr_out = 1'b1;
      intr_id = {1'b0, 3'b000}; // Start with sync ID base (0)
      casez (sync_masked)
        8'b1???????: intr_id[2:0] = 3'd7;
        8'b01??????: intr_id[2:0] = 3'd6;
        8'b001?????: intr_id[2:0] = 3'd5;
        8'b0001????: intr_id[2:0] = 3'd4;
        8'b00001???: intr_id[2:0] = 3'd3;
        8'b000001??: intr_id[2:0] = 3'd2;
        8'b0000001?: intr_id[2:0] = 3'd1;
        8'b00000001: intr_id[2:0] = 3'd0;
      endcase
    end else if (|async_masked) begin
      intr_out = 1'b1;
      intr_id = {1'b1, 3'b000}; // Handle async when not prioritized
      casez (async_masked)
        8'b1???????: intr_id[2:0] = 3'd7;
        8'b01??????: intr_id[2:0] = 3'd6;
        8'b001?????: intr_id[2:0] = 3'd5;
        8'b0001????: intr_id[2:0] = 3'd4;
        8'b00001???: intr_id[2:0] = 3'd3;
        8'b000001??: intr_id[2:0] = 3'd2;
        8'b0000001?: intr_id[2:0] = 3'd1;
        8'b00000001: intr_id[2:0] = 3'd0;
      endcase
    end else begin
      intr_out = 1'b0;
      intr_id = 4'd0;
    end
  end
endmodule