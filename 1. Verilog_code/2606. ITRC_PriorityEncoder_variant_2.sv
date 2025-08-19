//SystemVerilog
module ITRC_PriorityEncoder #(
    parameter WIDTH = 8,
    parameter [WIDTH*4-1:0] PRIORITY_LUT = 32'h01234567
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,
    input valid_in,
    output reg valid_out,
    output reg [3:0] highest_id
);

    // Pipeline registers
    reg [WIDTH-1:0] int_src_stage1;
    reg valid_stage1;
    reg [3:0] high_pri_stage1;
    reg [3:0] id_stage1_low;
    reg [3:0] highest_id_stage2;
    reg [3:0] high_pri_stage2;
    reg valid_stage2;
    
    // Priority lookup function
    function [3:0] get_priority;
        input integer index;
        begin
            get_priority = (PRIORITY_LUT >> (index*4)) & 4'hF;
        end
    endfunction
    
    // Input stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_src_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else begin
            int_src_stage1 <= int_src;
            valid_stage1 <= valid_in;
        end
    end
    
    // Priority comparison stage 1 - optimized for low 4 bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            high_pri_stage1 <= 0;
            id_stage1_low <= 0;
        end
        else if (valid_stage1) begin
            // Default values
            high_pri_stage1 <= 0;
            id_stage1_low <= 0;
            
            // Parallel priority comparison for low 4 bits
            if (int_src_stage1[0]) begin
                high_pri_stage1 <= get_priority(0);
                id_stage1_low <= 0;
            end
            if (int_src_stage1[1] && get_priority(1) > high_pri_stage1) begin
                high_pri_stage1 <= get_priority(1);
                id_stage1_low <= 1;
            end
            if (int_src_stage1[2] && get_priority(2) > high_pri_stage1) begin
                high_pri_stage1 <= get_priority(2);
                id_stage1_low <= 2;
            end
            if (int_src_stage1[3] && get_priority(3) > high_pri_stage1) begin
                high_pri_stage1 <= get_priority(3);
                id_stage1_low <= 3;
            end
        end
    end
    
    // Priority comparison stage 2 - optimized for high 4 bits
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            high_pri_stage2 <= 0;
            highest_id_stage2 <= 0;
        end
        else if (valid_stage1) begin
            // Initialize with stage 1 results
            high_pri_stage2 <= high_pri_stage1;
            highest_id_stage2 <= id_stage1_low;
            
            // Parallel priority comparison for high 4 bits
            if (int_src_stage1[4] && get_priority(4) > high_pri_stage1) begin
                high_pri_stage2 <= get_priority(4);
                highest_id_stage2 <= 4;
            end
            if (int_src_stage1[5] && get_priority(5) > high_pri_stage1) begin
                high_pri_stage2 <= get_priority(5);
                highest_id_stage2 <= 5;
            end
            if (int_src_stage1[6] && get_priority(6) > high_pri_stage1) begin
                high_pri_stage2 <= get_priority(6);
                highest_id_stage2 <= 6;
            end
            if (int_src_stage1[7] && get_priority(7) > high_pri_stage1) begin
                high_pri_stage2 <= get_priority(7);
                highest_id_stage2 <= 7;
            end
        end
    end
    
    // Valid signal pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 0;
            valid_out <= 0;
        end
        else begin
            valid_stage2 <= valid_stage1;
            valid_out <= valid_stage2;
        end
    end
    
    // Final output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            highest_id <= 0;
        end
        else if (valid_out) begin
            highest_id <= highest_id_stage2;
        end
    end
    
endmodule