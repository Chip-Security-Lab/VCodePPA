//SystemVerilog
`ifdef IEEE_1364_2005
`else
`define IEEE_1364_2005
`endif

module mixed_sync_async_intr_ctrl(
  input                clk,
  input                rst_n,
  input        [7:0]   async_intr,
  input        [7:0]   sync_intr,
  output  reg  [3:0]   intr_id,
  output  reg          intr_out
);

  // ------------------- Input Synchronization Stage (Stage 1) -------------------
  reg  [7:0] async_intr_sync1, async_intr_sync2;
  
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
  
  // ------------------- Configuration Stage (Stage 1) -------------------
  reg  [7:0] async_mask, sync_mask;
  reg        async_priority;
  
  // Mask and priority configuration registers
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      async_mask     <= 8'hFF;
      sync_mask      <= 8'hFF;
      async_priority <= 1'b1; // Default: async has priority
    end else begin
      // Mask registers would be updated via config interface (not shown)
    end
  end
  
  // ------------------- Interrupt Masking Stage (Stage 2) -------------------
  wire [7:0] async_masked_pre, sync_masked_pre;
  reg  [7:0] async_masked_stage2, sync_masked_stage2;
  
  assign async_masked_pre = async_intr_sync2 & async_mask;
  assign sync_masked_pre = sync_intr & sync_mask;
  
  // Pipeline register for masked interrupts
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      async_masked_stage2 <= 8'h0;
      sync_masked_stage2  <= 8'h0;
    end else begin
      async_masked_stage2 <= async_masked_pre;
      sync_masked_stage2  <= sync_masked_pre;
    end
  end
  
  // ------------------- Interrupt Presence Detection Stage (Stage 3) -------------------
  reg [7:0] async_masked_stage3, sync_masked_stage3;
  reg async_active_stage3, sync_active_stage3;
  reg async_priority_stage3;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      async_masked_stage3 <= 8'h0;
      sync_masked_stage3 <= 8'h0;
      async_active_stage3 <= 1'b0;
      sync_active_stage3  <= 1'b0;
      async_priority_stage3 <= 1'b0;
    end else begin
      async_masked_stage3 <= async_masked_stage2;
      sync_masked_stage3 <= sync_masked_stage2;
      async_active_stage3 <= |async_masked_stage2;
      sync_active_stage3  <= |sync_masked_stage2;
      async_priority_stage3 <= async_priority;
    end
  end
  
  // ------------------- Priority Resolution Stage 1 (Stage 4) -------------------
  reg        intr_valid_stage4;
  reg        is_async_source_stage4;
  reg [7:0]  selected_intr_pre;
  reg [7:0]  selected_intr_stage4;
  
  always @(*) begin
    // Determine interrupt source based on priority (combinational)
    if (async_active_stage3 && async_priority_stage3) begin
      selected_intr_pre = async_masked_stage3;
      is_async_source_stage4 = 1'b1;
      intr_valid_stage4 = 1'b1;
    end else if (sync_active_stage3) begin
      selected_intr_pre = sync_masked_stage3;
      is_async_source_stage4 = 1'b0;
      intr_valid_stage4 = 1'b1;
    end else if (async_active_stage3) begin
      selected_intr_pre = async_masked_stage3;
      is_async_source_stage4 = 1'b1;
      intr_valid_stage4 = 1'b1;
    end else begin
      selected_intr_pre = 8'h0;
      is_async_source_stage4 = 1'b0;
      intr_valid_stage4 = 1'b0;
    end
  end
  
  // ------------------- Priority Resolution Stage 2 (Stage 4) -------------------
  reg intr_valid_stage4_reg;
  reg is_async_source_stage4_reg;
  reg [7:0] selected_intr_stage4_reg;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      selected_intr_stage4_reg <= 8'h0;
      intr_valid_stage4_reg <= 1'b0;
      is_async_source_stage4_reg <= 1'b0;
    end else begin
      selected_intr_stage4_reg <= selected_intr_pre;
      intr_valid_stage4_reg <= intr_valid_stage4;
      is_async_source_stage4_reg <= is_async_source_stage4;
    end
  end
  
  // ------------------- Encoder Stage 1 (Stage 5) -------------------
  reg [2:0] encoded_id_stage5;
  reg intr_valid_stage5;
  reg is_async_source_stage5;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      encoded_id_stage5 <= 3'd0;
      intr_valid_stage5 <= 1'b0;
      is_async_source_stage5 <= 1'b0;
    end else begin
      intr_valid_stage5 <= intr_valid_stage4_reg;
      is_async_source_stage5 <= is_async_source_stage4_reg;
      
      case (1'b1) // Priority encoding split into multiple stages
        selected_intr_stage4_reg[7]: encoded_id_stage5 <= 3'd7;
        selected_intr_stage4_reg[6]: encoded_id_stage5 <= 3'd6;
        selected_intr_stage4_reg[5]: encoded_id_stage5 <= 3'd5;
        selected_intr_stage4_reg[4]: encoded_id_stage5 <= 3'd4;
        selected_intr_stage4_reg[3]: encoded_id_stage5 <= 3'd3;
        selected_intr_stage4_reg[2]: encoded_id_stage5 <= 3'd2;
        selected_intr_stage4_reg[1]: encoded_id_stage5 <= 3'd1;
        selected_intr_stage4_reg[0]: encoded_id_stage5 <= 3'd0;
        default:                     encoded_id_stage5 <= 3'd0;
      endcase
    end
  end
  
  // ------------------- Output Stage (Stage 6) -------------------
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id  <= 4'd0;
      intr_out <= 1'b0;
    end else begin
      intr_out <= intr_valid_stage5;
      intr_id  <= intr_valid_stage5 ? {is_async_source_stage5, encoded_id_stage5} : 4'd0;
    end
  end

endmodule