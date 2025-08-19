module cam_programmable #(parameter WIDTH=8, DEPTH=16)(
    input clk,
    input rst,
    input [1:0] match_mode, // 00: exact, 01: range, 10: mask
    input [WIDTH-1:0] search_data,
    input [WIDTH-1:0] lower_bound,
    input [WIDTH-1:0] upper_bound,
    input [WIDTH-1:0] search_mask,
    input valid_in,
    output valid_out,
    
    // Write interface
    input write_en,
    input [3:0] write_addr,
    input [WIDTH-1:0] write_data,
    
    // Output match lines
    output reg [DEPTH-1:0] match_lines
);
    // CAM storage
    reg [WIDTH-1:0] cam_entries [0:DEPTH-1];
    
    // Pipeline stage 1 registers (input capture)
    reg [1:0] match_mode_stage1;
    reg [WIDTH-1:0] search_data_stage1;
    reg [WIDTH-1:0] lower_bound_stage1;
    reg [WIDTH-1:0] upper_bound_stage1;
    reg [WIDTH-1:0] search_mask_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers (compute stage)
    reg [DEPTH-1:0] match_exact_stage2;
    reg [DEPTH-1:0] match_range_stage2;
    reg [DEPTH-1:0] match_mask_stage2;
    reg [1:0] match_mode_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers (selection stage)
    reg [DEPTH-1:0] match_lines_stage3;
    reg valid_stage3;
    
    // Write operation
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                cam_entries[i] <= {WIDTH{1'b0}};
        end else if (write_en) begin
            cam_entries[write_addr] <= write_data;
        end
    end
    
    // Pipeline stage 1: Input capture
    always @(posedge clk) begin
        if (rst) begin
            match_mode_stage1 <= 2'b00;
            search_data_stage1 <= {WIDTH{1'b0}};
            lower_bound_stage1 <= {WIDTH{1'b0}};
            upper_bound_stage1 <= {WIDTH{1'b0}};
            search_mask_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            match_mode_stage1 <= match_mode;
            search_data_stage1 <= search_data;
            lower_bound_stage1 <= lower_bound;
            upper_bound_stage1 <= upper_bound;
            search_mask_stage1 <= search_mask;
            valid_stage1 <= valid_in;
        end
    end
    
    // Pipeline stage 2: Compute matches in parallel
    integer j;
    always @(posedge clk) begin
        if (rst) begin
            match_exact_stage2 <= {DEPTH{1'b0}};
            match_range_stage2 <= {DEPTH{1'b0}};
            match_mask_stage2 <= {DEPTH{1'b0}};
            match_mode_stage2 <= 2'b00;
            valid_stage2 <= 1'b0;
        end else begin
            for (j = 0; j < DEPTH; j = j + 1) begin
                // Compute all match types in parallel
                match_exact_stage2[j] <= (cam_entries[j] == search_data_stage1);
                match_range_stage2[j] <= (cam_entries[j] >= lower_bound_stage1) && 
                                          (cam_entries[j] <= upper_bound_stage1);
                match_mask_stage2[j] <= ((cam_entries[j] & search_mask_stage1) == 
                                          (search_data_stage1 & search_mask_stage1));
            end
            match_mode_stage2 <= match_mode_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline stage 3: Select appropriate match type and output
    always @(posedge clk) begin
        if (rst) begin
            match_lines_stage3 <= {DEPTH{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            if (match_mode_stage2 == 2'b00) begin
                match_lines_stage3 <= match_exact_stage2;
            end else if (match_mode_stage2 == 2'b01) begin
                match_lines_stage3 <= match_range_stage2;
            end else if (match_mode_stage2 == 2'b10) begin
                match_lines_stage3 <= match_mask_stage2;
            end else begin
                match_lines_stage3 <= match_exact_stage2; // Default to exact match
            end
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output assignment
    always @(posedge clk) begin
        if (rst) begin
            match_lines <= {DEPTH{1'b0}};
        end else begin
            match_lines <= match_lines_stage3;
        end
    end
    
    // Valid output signal
    assign valid_out = valid_stage3;
    
endmodule