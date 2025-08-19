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
    
    // Pre-computed values for different match modes
    wire [WIDTH-1:0] masked_search_data;
    reg [DEPTH-1:0] exact_match_lines;
    reg [DEPTH-1:0] range_match_lines;
    reg [DEPTH-1:0] mask_match_lines;
    
    // Pre-compute masked search data
    assign masked_search_data = search_data & search_mask;
    
    // CAM memory write operation
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                cam_entries[i] <= {WIDTH{1'b0}};
        end else if (write_en) begin
            cam_entries[write_addr] <= write_data;
        end
    end
    
    // Compute exact match pattern
    integer j;
    always @(*) begin
        for (j = 0; j < DEPTH; j = j + 1) begin
            exact_match_lines[j] = (cam_entries[j] == search_data);
        end
    end
    
    // Compute range match pattern
    integer k;
    always @(*) begin
        for (k = 0; k < DEPTH; k = k + 1) begin
            range_match_lines[k] = (cam_entries[k] >= lower_bound) && (cam_entries[k] <= upper_bound);
        end
    end
    
    // Compute mask match pattern
    integer m;
    always @(*) begin
        for (m = 0; m < DEPTH; m = m + 1) begin
            mask_match_lines[m] = ((cam_entries[m] & search_mask) == masked_search_data);
        end
    end
    
    // Final match mode selection
    always @(*) begin
        case (match_mode)
            2'b00: match_lines = exact_match_lines;
            2'b01: match_lines = range_match_lines;
            2'b10: match_lines = mask_match_lines;
            default: match_lines = exact_match_lines;
        endcase
    end
endmodule