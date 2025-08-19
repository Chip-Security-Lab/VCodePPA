//SystemVerilog
module boundary_check_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] upper_bound, lower_bound,
    output reg [$clog2(WIDTH)-1:0] priority_pos,
    output reg in_bounds, valid
);
    // Stage 1 registers
    reg [WIDTH-1:0] data_stage1, upper_bound_stage1, lower_bound_stage1;
    reg stage1_valid;
    
    // Stage 2 registers
    reg [WIDTH-1:0] data_stage2, upper_bound_stage2, lower_bound_stage2;
    reg stage2_valid;
    reg in_bounds_stage2;
    
    // Stage 3 registers
    reg [WIDTH-1:0] masked_data_stage3;
    reg stage3_valid;
    reg in_bounds_stage3;
    
    // Stage 4 registers
    reg [WIDTH-1:0] masked_data_stage4;
    reg stage4_valid;
    reg in_bounds_stage4;
    reg [$clog2(WIDTH)-1:0] priority_pos_stage4;
    
    // Stage 1: Input capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            upper_bound_stage1 <= 0;
            lower_bound_stage1 <= 0;
            stage1_valid <= 0;
        end else begin
            data_stage1 <= data;
            upper_bound_stage1 <= upper_bound;
            lower_bound_stage1 <= lower_bound;
            stage1_valid <= 1'b1;
        end
    end
    
    // Stage 2: Lower bound check
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 0;
            upper_bound_stage2 <= 0;
            lower_bound_stage2 <= 0;
            in_bounds_stage2 <= 0;
            stage2_valid <= 0;
        end else begin
            data_stage2 <= data_stage1;
            upper_bound_stage2 <= upper_bound_stage1;
            lower_bound_stage2 <= lower_bound_stage1;
            in_bounds_stage2 <= (data_stage1 >= lower_bound_stage1);
            stage2_valid <= stage1_valid;
        end
    end
    
    // Stage 3: Upper bound check and data masking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_data_stage3 <= 0;
            in_bounds_stage3 <= 0;
            stage3_valid <= 0;
        end else begin
            masked_data_stage3 <= (in_bounds_stage2 && (data_stage2 <= upper_bound_stage2)) ? data_stage2 : 0;
            in_bounds_stage3 <= in_bounds_stage2 && (data_stage2 <= upper_bound_stage2);
            stage3_valid <= stage2_valid;
        end
    end
    
    // Stage 4: Priority encoding preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_data_stage4 <= 0;
            in_bounds_stage4 <= 0;
            stage4_valid <= 0;
            priority_pos_stage4 <= 0;
        end else begin
            masked_data_stage4 <= masked_data_stage3;
            in_bounds_stage4 <= in_bounds_stage3;
            stage4_valid <= stage3_valid;
            
            // Priority encoding
            priority_pos_stage4 <= 0;
            for (integer i = WIDTH-1; i >= 0; i = i - 1)
                if (masked_data_stage3[i]) priority_pos_stage4 <= i[$clog2(WIDTH)-1:0];
        end
    end
    
    // Stage 5: Output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_pos <= 0;
            in_bounds <= 0;
            valid <= 0;
        end else begin
            priority_pos <= priority_pos_stage4;
            in_bounds <= in_bounds_stage4;
            valid <= stage4_valid && |masked_data_stage4;
        end
    end
endmodule