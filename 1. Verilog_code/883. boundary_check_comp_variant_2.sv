//SystemVerilog
module boundary_check_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] upper_bound, lower_bound,
    output reg [$clog2(WIDTH)-1:0] priority_pos,
    output reg in_bounds, valid
);
    // Stage 1 registers - Computation intermediates
    reg [WIDTH-1:0] upper_diff_stage1, lower_diff_stage1;
    reg upper_borrow_stage1, lower_borrow_stage1;
    
    // Stage 2 registers - Pipeline registers for bounding calculation
    reg [WIDTH-1:0] data_stage2;
    reg in_bounds_stage2;
    
    // Stage 3 registers - Pipeline registers for priority encoding
    reg [WIDTH-1:0] masked_data_stage3;
    
    // LUTs for subtraction
    reg [3:0] upper_lut [0:15];
    reg [3:0] lower_lut [0:15];
    
    // LUT initialization for borrow calculation
    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            upper_lut[i] = (i[3:0] < 4'b1010) ? i[3:0] : (i[3:0] - 4'b1010);
            lower_lut[i] = (i[3:0] < 4'b1010) ? i[3:0] : (i[3:0] - 4'b1010);
        end
    end
    
    // Stage 1: Calculate differences and borrows
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            upper_diff_stage1 <= 0;
            lower_diff_stage1 <= 0;
            upper_borrow_stage1 <= 0;
            lower_borrow_stage1 <= 0;
            data_stage2 <= 0;
        end else begin
            // Register input data for stage 2
            data_stage2 <= data;
            
            // Subtraction using LUT for upper bound check (upper_bound - data)
            for (i = 0; i < WIDTH/4; i = i + 1) begin
                if (i == 0) begin
                    {upper_borrow_stage1, upper_diff_stage1[i*4+:4]} <= {1'b0, upper_lut[{upper_bound[i*4+:4], data[i*4+:4]}]};
                end else begin
                    {upper_borrow_stage1, upper_diff_stage1[i*4+:4]} <= {1'b0, upper_lut[{upper_bound[i*4+:4], data[i*4+:4], upper_borrow_stage1}]};
                end
            end
            
            // Subtraction using LUT for lower bound check (data - lower_bound)
            for (i = 0; i < WIDTH/4; i = i + 1) begin
                if (i == 0) begin
                    {lower_borrow_stage1, lower_diff_stage1[i*4+:4]} <= {1'b0, lower_lut[{data[i*4+:4], lower_bound[i*4+:4]}]};
                end else begin
                    {lower_borrow_stage1, lower_diff_stage1[i*4+:4]} <= {1'b0, lower_lut[{data[i*4+:4], lower_bound[i*4+:4], lower_borrow_stage1}]};
                end
            end
        end
    end
    
    // Stage 2: Determine in_bounds and prepare masked data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_bounds_stage2 <= 0;
            masked_data_stage3 <= 0;
        end else begin
            // Check if data is within bounds using the calculated differences
            in_bounds_stage2 <= (!upper_borrow_stage1) && (!lower_borrow_stage1);
            
            // Mask data if outside bounds
            masked_data_stage3 <= in_bounds_stage2 ? data_stage2 : 0;
        end
    end
    
    // Stage 3: Priority encoding and final outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_pos <= 0;
            in_bounds <= 0;
            valid <= 0;
        end else begin
            // Forward in_bounds signal
            in_bounds <= in_bounds_stage2;
            
            // Determine valid flag
            valid <= |masked_data_stage3;
            
            // Find highest priority bit using priority encoder
            priority_pos <= 0;
            for (i = WIDTH-1; i >= 0; i = i - 1)
                if (masked_data_stage3[i]) priority_pos <= i[$clog2(WIDTH)-1:0];
        end
    end
endmodule