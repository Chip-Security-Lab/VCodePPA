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

    // Pipeline registers
    reg [WIDTH-1:0] write_data_stage1;
    reg [3:0] write_addr_stage1;
    reg write_en_stage1;
    
    reg [WIDTH-1:0] search_data_stage1;
    reg [WIDTH-1:0] lower_bound_stage1;
    reg [WIDTH-1:0] upper_bound_stage1;
    reg [WIDTH-1:0] search_mask_stage1;
    reg [1:0] match_mode_stage1;

    // LUT-based subtractor components
    reg [3:0] comp_diff_lower;
    reg [3:0] comp_diff_upper;
    reg comp_lower_borrow;
    reg comp_upper_borrow;
    
    // LUT for borrow generation (4-bit)
    reg [15:0] borrow_lut;
    
    // LUT for difference calculation (4-bit)
    reg [255:0] difference_lut;
    
    // Initialize LUTs
    integer k, l;
    initial begin
        // Borrow LUT (stores whether subtraction produces a borrow)
        for (k = 0; k < 16; k = k + 1) begin
            for (l = 0; l < 16; l = l + 1) begin
                borrow_lut[k] = (k < l) ? 1'b1 : 1'b0;
            end
        end
        
        // Difference LUT (stores a - b results, 4-bit)
        for (k = 0; k < 16; k = k + 1) begin
            for (l = 0; l < 16; l = l + 1) begin
                difference_lut[{k, l}] = k - l;
            end
        end
    end
    
    // Write operation
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                cam_entries[i] <= {WIDTH{1'b0}};
        end else if (write_en_stage1) begin
            cam_entries[write_addr_stage1] <= write_data_stage1;
        end
    end

    // Pipeline control logic
    always @(posedge clk) begin
        if (rst) begin
            write_data_stage1 <= {WIDTH{1'b0}};
            write_addr_stage1 <= 4'b0;
            write_en_stage1 <= 1'b0;
            search_data_stage1 <= {WIDTH{1'b0}};
            lower_bound_stage1 <= {WIDTH{1'b0}};
            upper_bound_stage1 <= {WIDTH{1'b0}};
            search_mask_stage1 <= {WIDTH{1'b0}};
            match_mode_stage1 <= 2'b00;
        end else begin
            write_data_stage1 <= write_data;
            write_addr_stage1 <= write_addr;
            write_en_stage1 <= write_en;
            search_data_stage1 <= search_data;
            lower_bound_stage1 <= lower_bound;
            upper_bound_stage1 <= upper_bound;
            search_mask_stage1 <= search_mask;
            match_mode_stage1 <= match_mode;
        end
    end

    // LUT-based comparator for range checking
    function automatic is_in_range;
        input [WIDTH-1:0] value;
        input [WIDTH-1:0] lower;
        input [WIDTH-1:0] upper;
        reg lower_match, upper_match;
        begin
            // Using only 4-bit slice for LUT-based comparisons
            comp_diff_lower = difference_lut[{value[3:0], lower[3:0]}];
            comp_lower_borrow = borrow_lut[{value[3:0], lower[3:0]}];
            
            comp_diff_upper = difference_lut[{upper[3:0], value[3:0]}];
            comp_upper_borrow = borrow_lut[{upper[3:0], value[3:0]}];
            
            // Check if value >= lower using the borrow flag
            lower_match = ~comp_lower_borrow;
            
            // Check if value <= upper using the borrow flag
            upper_match = ~comp_upper_borrow;
            
            // For values wider than 4 bits, combine with direct comparison
            if (WIDTH > 4) begin
                lower_match = lower_match && (value[WIDTH-1:4] >= lower[WIDTH-1:4]);
                upper_match = upper_match && (value[WIDTH-1:4] <= upper[WIDTH-1:4]);
            end
            
            is_in_range = lower_match && upper_match;
        end
    endfunction

    // Match operation
    integer j;
    always @(*) begin
        for (j = 0; j < DEPTH; j = j + 1) begin
            case (match_mode_stage1)
                2'b00: // Exact match
                    match_lines[j] = (cam_entries[j] == search_data_stage1);
                
                2'b01: // Range match using LUT-based subtractor
                    match_lines[j] = is_in_range(cam_entries[j], lower_bound_stage1, upper_bound_stage1);
                
                2'b10: // Mask match (masked bits ignored)
                    match_lines[j] = ((cam_entries[j] & search_mask_stage1) == 
                                     (search_data_stage1 & search_mask_stage1));
                
                default: // Default to exact match
                    match_lines[j] = (cam_entries[j] == search_data_stage1);
            endcase
        end
    end
endmodule