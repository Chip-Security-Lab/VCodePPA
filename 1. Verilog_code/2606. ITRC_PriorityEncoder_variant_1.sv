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

    reg [3:0] high_pri_stage1;
    reg [3:0] high_pri_stage2;
    reg [3:0] high_pri_stage3;
    reg [3:0] highest_id_stage1;
    reg [3:0] highest_id_stage2;
    reg [3:0] highest_id_stage3;
    
    function [3:0] get_priority;
        input integer index;
        begin
            get_priority = (PRIORITY_LUT >> (index*4)) & 4'hF;
        end
    endfunction
    
    // Stage 1: Process first 2 sources
    always @(posedge clk) begin
        if (!rst_n) begin
            high_pri_stage1 <= 0;
            highest_id_stage1 <= 0;
        end
        else begin
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
        end
    end
    
    // Stage 2: Process next 3 sources
    always @(posedge clk) begin
        if (!rst_n) begin
            high_pri_stage2 <= 0;
            highest_id_stage2 <= 0;
        end
        else begin
            high_pri_stage2 <= high_pri_stage1;
            highest_id_stage2 <= highest_id_stage1;
            
            if (int_src[2] && (get_priority(2) > high_pri_stage2)) begin
                high_pri_stage2 <= get_priority(2);
                highest_id_stage2 <= 2;
            end
            if (int_src[3] && (get_priority(3) > high_pri_stage2)) begin
                high_pri_stage2 <= get_priority(3);
                highest_id_stage2 <= 3;
            end
            if (int_src[4] && (get_priority(4) > high_pri_stage2)) begin
                high_pri_stage2 <= get_priority(4);
                highest_id_stage2 <= 4;
            end
        end
    end

    // Stage 3: Process last 3 sources
    always @(posedge clk) begin
        if (!rst_n) begin
            high_pri_stage3 <= 0;
            highest_id_stage3 <= 0;
        end
        else begin
            high_pri_stage3 <= high_pri_stage2;
            highest_id_stage3 <= highest_id_stage2;
            
            if (int_src[5] && (get_priority(5) > high_pri_stage3)) begin
                high_pri_stage3 <= get_priority(5);
                highest_id_stage3 <= 5;
            end
            if (int_src[6] && (get_priority(6) > high_pri_stage3)) begin
                high_pri_stage3 <= get_priority(6);
                highest_id_stage3 <= 6;
            end
            if (int_src[7] && (get_priority(7) > high_pri_stage3)) begin
                high_pri_stage3 <= get_priority(7);
                highest_id_stage3 <= 7;
            end
        end
    end
    
    // Final stage: Output
    always @(posedge clk) begin
        if (!rst_n) begin
            highest_id <= 0;
        end
        else begin
            highest_id <= highest_id_stage3;
        end
    end
    
endmodule