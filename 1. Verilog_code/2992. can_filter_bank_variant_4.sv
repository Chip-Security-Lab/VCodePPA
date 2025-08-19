//SystemVerilog - IEEE 1364-2005
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

  // Pipeline stage 1 signals
  reg [10:0] rx_id_pipe1;
  reg [NUM_FILTERS-1:0] filter_enable_pipe1;
  reg [10:0] filter_id_pipe1 [0:NUM_FILTERS-1];
  reg [10:0] filter_mask_pipe1 [0:NUM_FILTERS-1];
  reg id_valid_pipe1;
  
  // Pipeline stage 2 signals
  reg [10:0] masked_rx_id_pipe2 [0:NUM_FILTERS-1]; // Separate masked rx_id for each filter
  reg [10:0] masked_filter_id_pipe2 [0:NUM_FILTERS-1];
  reg [NUM_FILTERS-1:0] filter_enable_pipe2;
  reg id_valid_pipe2;

  // Final comparison results
  reg [NUM_FILTERS-1:0] filter_match_result;
  
  integer i;
  
  // Pipeline stage 1: Register inputs
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_id_pipe1 <= 11'b0;
      id_valid_pipe1 <= 1'b0;
      filter_enable_pipe1 <= {NUM_FILTERS{1'b0}};
      for (i = 0; i < NUM_FILTERS; i = i + 1) begin
        filter_id_pipe1[i] <= 11'b0;
        filter_mask_pipe1[i] <= 11'b0;
      end
    end else begin
      rx_id_pipe1 <= rx_id;
      id_valid_pipe1 <= id_valid;
      filter_enable_pipe1 <= filter_enable;
      for (i = 0; i < NUM_FILTERS; i = i + 1) begin
        filter_id_pipe1[i] <= filter_id[i];
        filter_mask_pipe1[i] <= filter_mask[i];
      end
    end
  end
  
  // Pipeline stage 2: Compute masked values (optimized)
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      filter_enable_pipe2 <= {NUM_FILTERS{1'b0}};
      id_valid_pipe2 <= 1'b0;
      for (i = 0; i < NUM_FILTERS; i = i + 1) begin
        masked_rx_id_pipe2[i] <= 11'b0;
        masked_filter_id_pipe2[i] <= 11'b0;
      end
    end else begin
      filter_enable_pipe2 <= filter_enable_pipe1;
      id_valid_pipe2 <= id_valid_pipe1;
      for (i = 0; i < NUM_FILTERS; i = i + 1) begin
        // Pre-compute masked rx_id for each filter individually
        masked_rx_id_pipe2[i] <= rx_id_pipe1 & filter_mask_pipe1[i];
        masked_filter_id_pipe2[i] <= filter_id_pipe1[i] & filter_mask_pipe1[i];
      end
    end
  end
  
  // Final stage: Compute match results using pre-computed masked values
  // This eliminates redundant masking operations in the comparison logic
  always @(*) begin
    filter_match_result = {NUM_FILTERS{1'b0}};
    
    for (i = 0; i < NUM_FILTERS; i = i + 1) begin
      // Direct equality comparison between pre-masked values
      if (filter_enable_pipe2[i]) begin
        filter_match_result[i] = (masked_rx_id_pipe2[i] == masked_filter_id_pipe2[i]);
      end
    end
  end
  
  // Optimize output stage to reduce path delay
  reg match_any;
  
  always @(*) begin
    // Efficient reduction OR operation
    match_any = 1'b0;
    for (i = 0; i < NUM_FILTERS; i = i + 1) begin
      match_any = match_any | (filter_match_result[i] & filter_enable_pipe2[i]);
    end
  end
  
  // Register final outputs
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_match <= 1'b0;
      match_filter <= {NUM_FILTERS{1'b0}};
    end else if (id_valid_pipe2) begin
      match_filter <= filter_match_result & filter_enable_pipe2;
      id_match <= match_any;
    end
  end
  
endmodule