module cam_programmable #(parameter WIDTH=8, DEPTH=16)(
    input clk,
    input rst,
    input [1:0] match_mode, // 00: exact, 01: range, 10: mask
    input [WIDTH-1:0] search_data,
    input [WIDTH-1:0] lower_bound,
    input [WIDTH-1:0] upper_bound,
    input [WIDTH-1:0] search_mask,
    
    // Write interface
    input write_en,
    input [3:0] write_addr,
    input [WIDTH-1:0] write_data,
    
    // Output match lines
    output reg [DEPTH-1:0] match_lines
);
    // CAM storage
    reg [WIDTH-1:0] cam_entries [0:DEPTH-1];
    
    // Write operation with one-hot address decoding for better timing
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                cam_entries[i] <= {WIDTH{1'b0}};
        end else if (write_en) begin
            cam_entries[write_addr] <= write_data;
        end
    end
    
    // Pipeline Stage 1: Register and pre-compute constants
    reg [1:0] match_mode_pipe1;
    reg [WIDTH-1:0] search_data_pipe1;
    reg [WIDTH-1:0] lower_bound_pipe1;
    reg [WIDTH-1:0] upper_bound_pipe1;
    reg [WIDTH-1:0] masked_search_pipe1; // Pre-compute masked search data
    reg [WIDTH-1:0] search_mask_pipe1;
    reg [WIDTH-1:0] cam_data_pipe1 [0:DEPTH-1];
    
    always @(posedge clk) begin
        if (rst) begin
            match_mode_pipe1 <= 2'b00;
            search_data_pipe1 <= {WIDTH{1'b0}};
            lower_bound_pipe1 <= {WIDTH{1'b0}};
            upper_bound_pipe1 <= {WIDTH{1'b0}};
            search_mask_pipe1 <= {WIDTH{1'b0}};
            masked_search_pipe1 <= {WIDTH{1'b0}};
            for (i = 0; i < DEPTH; i = i + 1)
                cam_data_pipe1[i] <= {WIDTH{1'b0}};
        end else begin
            match_mode_pipe1 <= match_mode;
            search_data_pipe1 <= search_data;
            lower_bound_pipe1 <= lower_bound;
            upper_bound_pipe1 <= upper_bound;
            search_mask_pipe1 <= search_mask;
            masked_search_pipe1 <= search_data & search_mask; // Pre-compute for mask match
            
            // Register all CAM entries in parallel
            for (i = 0; i < DEPTH; i = i + 1)
                cam_data_pipe1[i] <= cam_entries[i];
        end
    end
    
    // Pipeline Stage 2: Optimized comparisons
    reg [DEPTH-1:0] match_result_pipe2;
    reg [1:0] match_mode_pipe2;
    reg [WIDTH-1:0] masked_data [0:DEPTH-1]; // Store masked data for each entry
    
    always @(posedge clk) begin
        if (rst) begin
            match_result_pipe2 <= {DEPTH{1'b0}};
            match_mode_pipe2 <= 2'b00;
            for (i = 0; i < DEPTH; i = i + 1)
                masked_data[i] <= {WIDTH{1'b0}};
        end else begin
            match_mode_pipe2 <= match_mode_pipe1;
            
            for (i = 0; i < DEPTH; i = i + 1) begin
                // Compute masked data for each entry (used by mask match)
                masked_data[i] <= cam_data_pipe1[i] & search_mask_pipe1;
                
                // Combined match logic for all modes
                case (match_mode_pipe1)
                    2'b00: // Exact match - direct equality comparison
                        match_result_pipe2[i] <= (cam_data_pipe1[i] == search_data_pipe1);
                    
                    2'b01: // Range match - check both bounds in one step
                        match_result_pipe2[i] <= ((cam_data_pipe1[i] >= lower_bound_pipe1) && 
                                              (cam_data_pipe1[i] <= upper_bound_pipe1));
                    
                    2'b10: // Mask match - use pre-computed masked search data
                        match_result_pipe2[i] <= (masked_data[i] == masked_search_pipe1);
                    
                    default: // Default to exact match
                        match_result_pipe2[i] <= (cam_data_pipe1[i] == search_data_pipe1);
                endcase
            end
        end
    end
    
    // Pipeline Stage 3: Register final results
    always @(posedge clk) begin
        if (rst) begin
            match_lines <= {DEPTH{1'b0}};
        end else begin
            match_lines <= match_result_pipe2;
        end
    end
endmodule