module hierarchical_intr_ctrl #(
  parameter GROUPS = 4,
  parameter SOURCES_PER_GROUP = 4
)(
  input clk, rst_n,
  input [GROUPS*SOURCES_PER_GROUP-1:0] intr_sources,
  input [GROUPS-1:0] group_mask,
  input [GROUPS*SOURCES_PER_GROUP-1:0] source_masks,
  output reg [$clog2(GROUPS)+$clog2(SOURCES_PER_GROUP)-1:0] intr_id,
  output reg valid
);
    // Simplify by using slices instead of arrays
    wire [GROUPS-1:0] group_active;
    reg [$clog2(SOURCES_PER_GROUP)-1:0] source_ids [0:GROUPS-1];
    integer i, j;
    
    // Generate group activity signals
    genvar g;
    generate
        for (g = 0; g < GROUPS; g = g + 1) begin : group_gen
            wire [SOURCES_PER_GROUP-1:0] masked_sources;
            assign masked_sources = intr_sources[g*SOURCES_PER_GROUP +: SOURCES_PER_GROUP] & 
                                    source_masks[g*SOURCES_PER_GROUP +: SOURCES_PER_GROUP];
            
            // Group is active if any masked source is active and group is not masked
            assign group_active[g] = |masked_sources & group_mask[g];
        end
    endgenerate
    
    // Find highest priority source within each group
    always @* begin
        for (i = 0; i < GROUPS; i = i + 1) begin
            source_ids[i] = {$clog2(SOURCES_PER_GROUP){1'b0}};
            for (j = SOURCES_PER_GROUP-1; j >= 0; j = j - 1) begin
                if (intr_sources[i*SOURCES_PER_GROUP+j] & source_masks[i*SOURCES_PER_GROUP+j]) 
                    source_ids[i] = j[$clog2(SOURCES_PER_GROUP)-1:0];
            end
        end
    end
    
    // Group-level priority encoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            intr_id <= {($clog2(GROUPS)+$clog2(SOURCES_PER_GROUP)){1'b0}};
            valid <= 1'b0;
        end else begin
            valid <= |group_active;
            
            // Find highest priority group
            intr_id <= {($clog2(GROUPS)+$clog2(SOURCES_PER_GROUP)){1'b0}};
            for (i = GROUPS-1; i >= 0; i = i - 1) begin
                if (group_active[i]) begin
                    intr_id <= {i[$clog2(GROUPS)-1:0], source_ids[i]};
                end
            end
        end
    end
endmodule