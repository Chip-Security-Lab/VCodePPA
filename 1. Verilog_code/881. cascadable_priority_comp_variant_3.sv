//SystemVerilog
module cascadable_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_in,
    input cascade_in_valid,
    input [$clog2(WIDTH)-1:0] cascade_in_idx,
    output reg cascade_out_valid,
    output reg [$clog2(WIDTH)-1:0] cascade_out_idx
);
    // === Stage 1: Local Priority Detection ===
    reg local_valid_stage1;
    reg [WIDTH-1:0] data_in_stage1;
    reg cascade_in_valid_stage1;
    reg [$clog2(WIDTH)-1:0] cascade_in_idx_stage1;
    
    always @(*) begin
        // Register stage for input data
        local_valid_stage1 = |data_in;
        data_in_stage1 = data_in;
        cascade_in_valid_stage1 = cascade_in_valid;
        cascade_in_idx_stage1 = cascade_in_idx;
    end
    
    // === Stage 2: Priority Encoding Logic ===
    reg [$clog2(WIDTH)-1:0] local_idx_stage2;
    reg local_valid_stage2;
    reg cascade_in_valid_stage2;
    reg [$clog2(WIDTH)-1:0] cascade_in_idx_stage2;
    
    // Optimized priority encoder with balanced logic depth
    function [$clog2(WIDTH)-1:0] find_priority_index;
        input [WIDTH-1:0] data;
        integer i;
        reg found;
        begin
            find_priority_index = 0;
            found = 0;
            // Scan from MSB to LSB with improved algorithm
            for (i = WIDTH-1; i >= 0; i = i - 1) begin
                if (data[i] && !found) begin
                    find_priority_index = i[$clog2(WIDTH)-1:0];
                    found = 1;
                end
            end
        end
    endfunction
    
    always @(*) begin
        // Priority encoding stage
        local_idx_stage2 = find_priority_index(data_in_stage1);
        local_valid_stage2 = local_valid_stage1;
        cascade_in_valid_stage2 = cascade_in_valid_stage1;
        cascade_in_idx_stage2 = cascade_in_idx_stage1;
    end
    
    // === Stage 3: Cascade Selection Logic ===
    always @(*) begin
        // Output cascade decision logic with clear data flow
        if (local_valid_stage2) begin
            // Local priority detected, use local index
            cascade_out_valid = 1'b1;
            cascade_out_idx = local_idx_stage2;
        end else if (cascade_in_valid_stage2) begin
            // No local priority, but cascade input is valid
            cascade_out_valid = 1'b1;
            cascade_out_idx = cascade_in_idx_stage2;
        end else begin
            // No priority detected in either input
            cascade_out_valid = 1'b0;
            cascade_out_idx = {($clog2(WIDTH)){1'b0}};
        end
    end
endmodule