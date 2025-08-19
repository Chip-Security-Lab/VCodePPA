//SystemVerilog
module can_filter_bank #(
  parameter NUM_FILTERS = 4
)(
  input wire clk, rst_n,
  input wire [10:0] rx_id,
  input wire id_valid,
  input wire [NUM_FILTERS-1:0] filter_enable,
  input wire [10:0] filter_id [0:NUM_FILTERS-1],
  input wire [10:0] filter_mask [0:NUM_FILTERS-1],
  output reg id_match,
  output reg [NUM_FILTERS-1:0] match_filter
);

  // Stage 1: Input registers
  reg [10:0] rx_id_stage1;
  reg id_valid_stage1;
  reg [NUM_FILTERS-1:0] filter_enable_stage1;
  reg [10:0] filter_id_stage1 [0:NUM_FILTERS-1];
  reg [10:0] filter_mask_stage1 [0:NUM_FILTERS-1];
  
  // Stage 2: Intermediate computation registers
  reg [10:0] rx_id_stage2;
  reg id_valid_stage2;
  reg [NUM_FILTERS-1:0] filter_enable_stage2;
  reg [10:0] masked_rx_id_stage2 [0:NUM_FILTERS-1];
  reg [10:0] masked_filter_id_stage2 [0:NUM_FILTERS-1];
  
  // Stage 3: Comparison results registers
  reg [NUM_FILTERS-1:0] match_condition_stage3;
  reg id_valid_stage3;
  
  // Stage 4: Final output registers
  reg id_match_stage4;
  reg [NUM_FILTERS-1:0] match_filter_stage4;
  
  integer i;
  
  // Stage 1: Register all input signals
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_id_stage1 <= 11'b0;
      id_valid_stage1 <= 1'b0;
      filter_enable_stage1 <= {NUM_FILTERS{1'b0}};
      for (i = 0; i < NUM_FILTERS; i = i + 1) begin
        filter_id_stage1[i] <= 11'b0;
        filter_mask_stage1[i] <= 11'b0;
      end
    end
    else begin
      rx_id_stage1 <= rx_id;
      id_valid_stage1 <= id_valid;
      filter_enable_stage1 <= filter_enable;
      for (i = 0; i < NUM_FILTERS; i = i + 1) begin
        filter_id_stage1[i] <= filter_id[i];
        filter_mask_stage1[i] <= filter_mask[i];
      end
    end
  end
  
  // Stage 2: Apply masks to IDs (separate computation pipeline stage)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_id_stage2 <= 11'b0;
      id_valid_stage2 <= 1'b0;
      filter_enable_stage2 <= {NUM_FILTERS{1'b0}};
      for (i = 0; i < NUM_FILTERS; i = i + 1) begin
        masked_rx_id_stage2[i] <= 11'b0;
        masked_filter_id_stage2[i] <= 11'b0;
      end
    end
    else begin
      rx_id_stage2 <= rx_id_stage1;
      id_valid_stage2 <= id_valid_stage1;
      filter_enable_stage2 <= filter_enable_stage1;
      for (i = 0; i < NUM_FILTERS; i = i + 1) begin
        masked_rx_id_stage2[i] <= rx_id_stage1 & filter_mask_stage1[i];
        masked_filter_id_stage2[i] <= filter_id_stage1[i] & filter_mask_stage1[i];
      end
    end
  end
  
  // Stage 3: Calculate match conditions (comparison pipeline stage)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      match_condition_stage3 <= {NUM_FILTERS{1'b0}};
      id_valid_stage3 <= 1'b0;
    end
    else begin
      id_valid_stage3 <= id_valid_stage2;
      for (i = 0; i < NUM_FILTERS; i = i + 1) begin
        match_condition_stage3[i] <= filter_enable_stage2[i] && 
                                (masked_rx_id_stage2[i] == masked_filter_id_stage2[i]);
      end
    end
  end
  
  // Stage 4: Final output decision (reduction and output pipeline stage)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_match <= 1'b0;
      match_filter <= {NUM_FILTERS{1'b0}};
      id_match_stage4 <= 1'b0;
      match_filter_stage4 <= {NUM_FILTERS{1'b0}};
    end
    else begin
      if (id_valid_stage3) begin
        // Reset intermediate outputs
        id_match_stage4 <= 1'b0;
        match_filter_stage4 <= {NUM_FILTERS{1'b0}};
        
        // Apply match conditions
        for (i = 0; i < NUM_FILTERS; i = i + 1) begin
          if (match_condition_stage3[i]) begin
            match_filter_stage4[i] <= 1'b1;
            id_match_stage4 <= 1'b1;
          end
        end
      end
      
      // Update final outputs
      id_match <= id_match_stage4;
      match_filter <= match_filter_stage4;
    end
  end
endmodule