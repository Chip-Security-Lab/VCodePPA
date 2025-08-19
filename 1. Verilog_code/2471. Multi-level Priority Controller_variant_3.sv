//SystemVerilog
module multi_level_intr_ctrl(
  input clk, reset_n,
  input [15:0] intr_source,
  input [1:0] level_sel,
  output reg [3:0] intr_id,
  output reg active
);
    // Improved first bit finder implementation with parallel logic
    function [3:0] find_first_bit;
        input [3:0] vec;
        begin
            find_first_bit = {4{vec[0]}} & 4'd0 |
                             {4{~vec[0] & vec[1]}} & 4'd1 |
                             {4{~vec[0] & ~vec[1] & vec[2]}} & 4'd2 |
                             {4{~vec[0] & ~vec[1] & ~vec[2] & vec[3]}} & 4'd3;
        end
    endfunction
    
    // Group interrupt signals for better timing
    wire [3:0] grp_valid;
    wire [3:0] high_id, med_id, low_id, sys_id;
    
    // Pre-compute group validity with better balance
    assign grp_valid[3] = |intr_source[15:12]; // high
    assign grp_valid[2] = |intr_source[11:8];  // med
    assign grp_valid[1] = |intr_source[7:4];   // low
    assign grp_valid[0] = |intr_source[3:0];   // sys
    
    // Pre-compute all IDs in parallel
    assign high_id = find_first_bit(intr_source[15:12]);
    assign med_id = find_first_bit(intr_source[11:8]);
    assign low_id = find_first_bit(intr_source[7:4]);
    assign sys_id = find_first_bit(intr_source[3:0]);
    
    // Pre-compute priority IDs for each level selection
    reg [3:0] next_id;
    reg next_active;
    
    // Pre-compute active flag in combinational logic
    always @(*) begin
        next_active = |grp_valid;
    end
    
    // Priority selection logic optimized for parallel evaluation
    always @(*) begin
        // Default value
        next_id = 4'd0;
        
        case (level_sel)
            2'b00: begin // high > med > low > sys
                if (grp_valid[3])      next_id = {2'b11, high_id};
                else if (grp_valid[2]) next_id = {2'b10, med_id};
                else if (grp_valid[1]) next_id = {2'b01, low_id};
                else if (grp_valid[0]) next_id = {2'b00, sys_id};
            end
            2'b01: begin // med > low > sys > high
                if (grp_valid[2])      next_id = {2'b10, med_id};
                else if (grp_valid[1]) next_id = {2'b01, low_id};
                else if (grp_valid[0]) next_id = {2'b00, sys_id};
                else if (grp_valid[3]) next_id = {2'b11, high_id};
            end
            2'b10: begin // low > sys > high > med
                if (grp_valid[1])      next_id = {2'b01, low_id};
                else if (grp_valid[0]) next_id = {2'b00, sys_id};
                else if (grp_valid[3]) next_id = {2'b11, high_id};
                else if (grp_valid[2]) next_id = {2'b10, med_id};
            end
            2'b11: begin // sys > high > med > low
                if (grp_valid[0])      next_id = {2'b00, sys_id};
                else if (grp_valid[3]) next_id = {2'b11, high_id};
                else if (grp_valid[2]) next_id = {2'b10, med_id};
                else if (grp_valid[1]) next_id = {2'b01, low_id};
            end
        endcase
    end
    
    // Register stage
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            intr_id <= 4'd0;
            active <= 1'b0;
        end else begin
            intr_id <= next_id;
            active <= next_active;
        end
    end
endmodule