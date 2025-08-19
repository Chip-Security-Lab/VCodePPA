//SystemVerilog
module hierarchical_intr_ctrl #(
  parameter GROUPS = 4,
  parameter SOURCES_PER_GROUP = 4
)(
  input clk, rst_n,
  input [GROUPS*SOURCES_PER_GROUP-1:0] intr_sources,
  input [GROUPS-1:0] group_mask,
  input [GROUPS*SOURCES_PER_GROUP-1:0] source_masks,
  output reg [$clog2(GROUPS)+$clog2(SOURCES_PER_GROUP)-1:0] intr_id,
  output reg valid,
  // Pipeline control signals
  input pipe_enable,
  input pipe_flush
);
  // Combination logic moved before first register stage
  wire [GROUPS*SOURCES_PER_GROUP-1:0] masked_sources_comb;
  wire [GROUPS-1:0] group_active_comb;
  
  // Masking and group activity calculation in combinational logic 
  genvar g;
  generate
    for (g = 0; g < GROUPS; g = g + 1) begin : group_gen
      wire [SOURCES_PER_GROUP-1:0] group_masked_sources;
      
      // Apply source masks in combinational logic
      assign group_masked_sources = intr_sources[g*SOURCES_PER_GROUP +: SOURCES_PER_GROUP] & 
                                    source_masks[g*SOURCES_PER_GROUP +: SOURCES_PER_GROUP];
      
      // Store full combinational result
      assign masked_sources_comb[g*SOURCES_PER_GROUP +: SOURCES_PER_GROUP] = group_masked_sources;
      
      // Group is active if any masked source is active and group is not masked
      assign group_active_comb[g] = |group_masked_sources & group_mask[g];
    end
  endgenerate
  
  // Pipeline stage 1: Register the results of combination logic instead of inputs
  reg [GROUPS-1:0] group_active_stage1;
  reg [GROUPS*SOURCES_PER_GROUP-1:0] masked_sources_stage1;
  reg stage1_valid;
  
  // Pipeline stage 2: Source priority finding
  reg [$clog2(SOURCES_PER_GROUP)-1:0] source_ids_stage2 [0:GROUPS-1];
  reg [GROUPS-1:0] group_active_stage2;
  reg stage2_valid;
  
  // Pipeline stage 1: Register already processed data
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      group_active_stage1 <= {GROUPS{1'b0}};
      masked_sources_stage1 <= {(GROUPS*SOURCES_PER_GROUP){1'b0}};
      stage1_valid <= 1'b0;
    end else if (pipe_flush) begin
      stage1_valid <= 1'b0;
    end else if (pipe_enable) begin
      // Store pre-processed data from combinational logic
      group_active_stage1 <= group_active_comb;
      masked_sources_stage1 <= masked_sources_comb;
      stage1_valid <= 1'b1;
    end
  end
  
  // Pipeline stage 2: Find highest priority source in each group
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (integer i = 0; i < GROUPS; i = i + 1) begin
        source_ids_stage2[i] <= {$clog2(SOURCES_PER_GROUP){1'b0}};
      end
      group_active_stage2 <= {GROUPS{1'b0}};
      stage2_valid <= 1'b0;
    end else if (pipe_flush) begin
      stage2_valid <= 1'b0;
    end else if (pipe_enable) begin
      // Find highest priority source within each group
      for (integer i = 0; i < GROUPS; i = i + 1) begin
        source_ids_stage2[i] = {$clog2(SOURCES_PER_GROUP){1'b0}};
        for (integer j = SOURCES_PER_GROUP-1; j >= 0; j = j - 1) begin
          if (masked_sources_stage1[i*SOURCES_PER_GROUP+j]) 
            source_ids_stage2[i] = j[$clog2(SOURCES_PER_GROUP)-1:0];
        end
      end
      
      group_active_stage2 <= group_active_stage1;
      stage2_valid <= stage1_valid;
    end
  end
  
  // Pipeline stage 3: Group-level priority encoding and output generation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= {($clog2(GROUPS)+$clog2(SOURCES_PER_GROUP)){1'b0}};
      valid <= 1'b0;
    end else if (pipe_flush) begin
      valid <= 1'b0;
    end else if (pipe_enable) begin
      valid <= stage2_valid & |group_active_stage2;
      
      // Find highest priority group
      intr_id <= {($clog2(GROUPS)+$clog2(SOURCES_PER_GROUP)){1'b0}};
      for (integer i = GROUPS-1; i >= 0; i = i - 1) begin
        if (group_active_stage2[i]) begin
          intr_id <= {i[$clog2(GROUPS)-1:0], source_ids_stage2[i]};
        end
      end
    end
  end
endmodule