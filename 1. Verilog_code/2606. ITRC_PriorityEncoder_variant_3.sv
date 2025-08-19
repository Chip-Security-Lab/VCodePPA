//SystemVerilog
module ITRC_PriorityEncoder #(
    parameter WIDTH = 8,
    parameter [WIDTH*4-1:0] PRIORITY_LUT = 32'h01234567
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,
    output reg [3:0] highest_id
);

    // Stage 1 signals
    reg [WIDTH-1:0] int_src_stage1;
    reg [3:0] high_pri_stage1;
    reg [3:0] highest_id_stage1;
    reg valid_stage1;

    // Stage 2 signals
    reg [3:0] high_pri_stage2;
    reg [3:0] highest_id_stage2;
    reg valid_stage2;

    // Stage 3 signals
    reg [3:0] high_pri_stage3;
    reg [3:0] highest_id_stage3;
    reg valid_stage3;

    // Extract values from PRIORITY_LUT
    function [3:0] get_priority;
        input integer index;
        begin
            get_priority = (PRIORITY_LUT >> (index*4)) & 4'hF;
        end
    endfunction

    // Input registration
    always @(posedge clk) begin
        if (!rst_n) begin
            int_src_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            int_src_stage1 <= int_src;
            valid_stage1 <= 1;
        end
    end

    // Stage 1: First 3 sources
    always @(posedge clk) begin
        if (!rst_n) begin
            high_pri_stage1 <= 0;
            highest_id_stage1 <= 0;
        end else begin
            high_pri_stage1 <= 0;
            highest_id_stage1 <= 0;
            
            if (int_src[0] && (get_priority(0) > high_pri_stage1)) begin
                high_pri_stage1 <= get_priority(0);
                highest_id_stage1 <= 0;
            end
            if (int_src[1] && (get_priority(1) > high_pri_stage1)) begin
                high_pri_stage1 <= get_priority(1);
                highest_id_stage1 <= 1;
            end
            if (int_src[2] && (get_priority(2) > high_pri_stage1)) begin
                high_pri_stage1 <= get_priority(2);
                highest_id_stage1 <= 2;
            end
        end
    end

    // Stage 2: Next 3 sources
    always @(posedge clk) begin
        if (!rst_n) begin
            high_pri_stage2 <= 0;
            highest_id_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            high_pri_stage2 <= high_pri_stage1;
            highest_id_stage2 <= highest_id_stage1;
            valid_stage2 <= valid_stage1;

            if (int_src_stage1[3] && (get_priority(3) > high_pri_stage2)) begin
                high_pri_stage2 <= get_priority(3);
                highest_id_stage2 <= 3;
            end
            if (int_src_stage1[4] && (get_priority(4) > high_pri_stage2)) begin
                high_pri_stage2 <= get_priority(4);
                highest_id_stage2 <= 4;
            end
            if (int_src_stage1[5] && (get_priority(5) > high_pri_stage2)) begin
                high_pri_stage2 <= get_priority(5);
                highest_id_stage2 <= 5;
            end
        end
    end

    // Stage 3: Last 2 sources
    always @(posedge clk) begin
        if (!rst_n) begin
            high_pri_stage3 <= 0;
            highest_id_stage3 <= 0;
            valid_stage3 <= 0;
        end else begin
            high_pri_stage3 <= high_pri_stage2;
            highest_id_stage3 <= highest_id_stage2;
            valid_stage3 <= valid_stage2;

            if (int_src_stage1[6] && (get_priority(6) > high_pri_stage3)) begin
                high_pri_stage3 <= get_priority(6);
                highest_id_stage3 <= 6;
            end
            if (int_src_stage1[7] && (get_priority(7) > high_pri_stage3)) begin
                high_pri_stage3 <= get_priority(7);
                highest_id_stage3 <= 7;
            end
        end
    end

    // Output stage
    always @(posedge clk) begin
        if (!rst_n) begin
            highest_id <= 0;
        end else begin
            highest_id <= highest_id_stage3;
        end
    end

endmodule