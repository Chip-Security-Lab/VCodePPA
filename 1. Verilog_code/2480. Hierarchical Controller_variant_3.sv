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
  output reg valid
);
    // Capture inputs in registers to reduce input-to-register delay
    reg [GROUPS*SOURCES_PER_GROUP-1:0] intr_sources_reg;
    reg [GROUPS-1:0] group_mask_reg;
    reg [GROUPS*SOURCES_PER_GROUP-1:0] source_masks_reg;
    
    // Internal processing signals
    wire [GROUPS-1:0] group_active;
    wire [$clog2(GROUPS)+$clog2(SOURCES_PER_GROUP)-1:0] next_intr_id;
    wire next_valid;
    reg [$clog2(SOURCES_PER_GROUP)-1:0] source_ids [0:GROUPS-1];
    reg [7:0] counter_j, counter_i;
    
    // Conditional inverse subtractor signals
    reg [7:0] minuend, subtrahend;
    reg sub_op;
    wire [7:0] diff_result;
    
    integer i, j;
    
    // Input registration stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            intr_sources_reg <= {(GROUPS*SOURCES_PER_GROUP){1'b0}};
            group_mask_reg <= {GROUPS{1'b0}};
            source_masks_reg <= {(GROUPS*SOURCES_PER_GROUP){1'b0}};
        end else begin
            intr_sources_reg <= intr_sources;
            group_mask_reg <= group_mask;
            source_masks_reg <= source_masks;
        end
    end
    
    // Generate group activity signals
    genvar g;
    generate
        for (g = 0; g < GROUPS; g = g + 1) begin : group_gen
            wire [SOURCES_PER_GROUP-1:0] masked_sources;
            assign masked_sources = intr_sources_reg[g*SOURCES_PER_GROUP +: SOURCES_PER_GROUP] & 
                                   source_masks_reg[g*SOURCES_PER_GROUP +: SOURCES_PER_GROUP];
            
            // Group is active if any masked source is active and group is not masked
            assign group_active[g] = |masked_sources & group_mask_reg[g];
        end
    endgenerate
    
    // Conditional inverse subtractor implementation
    always @* begin
        minuend = counter_j;    // First operand
        subtrahend = 8'd1;      // Second operand (constant 1)
        sub_op = 1'b1;          // Operation: 1 for subtraction
    end
    
    // Conditional inverse subtractor logic
    wire [7:0] inverted_subtrahend;
    wire [7:0] effective_subtrahend;
    wire carry_in;
    
    assign inverted_subtrahend = ~subtrahend;
    assign effective_subtrahend = sub_op ? inverted_subtrahend : subtrahend;
    assign carry_in = sub_op ? 1'b1 : 1'b0;
    
    // Adder implementation for conditional subtractor
    wire [8:0] sum_with_carry;
    assign sum_with_carry = {1'b0, minuend} + {1'b0, effective_subtrahend} + {{8{1'b0}}, carry_in};
    assign diff_result = sum_with_carry[7:0];
    
    // Find highest priority source within each group using conditional inverse subtractor
    always @* begin
        for (i = 0; i < GROUPS; i = i + 1) begin
            source_ids[i] = {$clog2(SOURCES_PER_GROUP){1'b0}};
            counter_j = SOURCES_PER_GROUP; // Starting value
            
            for (j = SOURCES_PER_GROUP-1; j >= 0; j = j - 1) begin
                // Update counter_j using conditional inverse subtractor
                minuend = counter_j;
                // diff_result is the computed difference from the subtractor module
                counter_j = diff_result;
                
                if (intr_sources_reg[i*SOURCES_PER_GROUP+j] & source_masks_reg[i*SOURCES_PER_GROUP+j]) 
                    source_ids[i] = counter_j[$clog2(SOURCES_PER_GROUP)-1:0];
            end
        end
    end
    
    // Group-level priority encoding - moved to combinational logic
    assign next_valid = |group_active;
    
    // Combinational block for determining next interrupt ID
    reg [$clog2(GROUPS)+$clog2(SOURCES_PER_GROUP)-1:0] temp_intr_id;
    
    always @* begin
        // Find highest priority group using conditional inverse subtractor
        temp_intr_id = {($clog2(GROUPS)+$clog2(SOURCES_PER_GROUP)){1'b0}};
        counter_i = GROUPS; // Starting value
        
        for (i = GROUPS-1; i >= 0; i = i - 1) begin
            // Update counter_i using conditional inverse subtractor
            minuend = counter_i;
            // diff_result is the computed difference
            counter_i = diff_result;
            
            if (group_active[i]) begin
                temp_intr_id = {counter_i[$clog2(GROUPS)-1:0], source_ids[i]};
            end
        end
    end
    
    assign next_intr_id = temp_intr_id;
    
    // Output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            intr_id <= {($clog2(GROUPS)+$clog2(SOURCES_PER_GROUP)){1'b0}};
            valid <= 1'b0;
        end else begin
            intr_id <= next_intr_id;
            valid <= next_valid;
        end
    end
endmodule