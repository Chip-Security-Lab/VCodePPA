module ITRC_PriorityEncoder #(
    parameter WIDTH = 8,
    parameter [WIDTH*4-1:0] PRIORITY_LUT = 32'h01234567
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,
    output reg [3:0] highest_id
);
    reg [3:0] high_pri;
    
    // Extract values from PRIORITY_LUT
    function [3:0] get_priority;
        input integer index;
        begin
            get_priority = (PRIORITY_LUT >> (index*4)) & 4'hF;
        end
    endfunction
    
    always @(posedge clk) begin
        if (!rst_n) begin
            highest_id <= 0;
            high_pri <= 0;
        end
        else begin
            high_pri = 0;
            highest_id <= 0;
            
            // Check each source individually
            if (int_src[0] && (get_priority(0) > high_pri)) begin
                high_pri = get_priority(0);
                highest_id <= 0;
            end
            if (int_src[1] && (get_priority(1) > high_pri)) begin
                high_pri = get_priority(1);
                highest_id <= 1;
            end
            if (int_src[2] && (get_priority(2) > high_pri)) begin
                high_pri = get_priority(2);
                highest_id <= 2;
            end
            if (int_src[3] && (get_priority(3) > high_pri)) begin
                high_pri = get_priority(3);
                highest_id <= 3;
            end
            if (int_src[4] && (get_priority(4) > high_pri)) begin
                high_pri = get_priority(4);
                highest_id <= 4;
            end
            if (int_src[5] && (get_priority(5) > high_pri)) begin
                high_pri = get_priority(5);
                highest_id <= 5;
            end
            if (int_src[6] && (get_priority(6) > high_pri)) begin
                high_pri = get_priority(6);
                highest_id <= 6;
            end
            if (int_src[7] && (get_priority(7) > high_pri)) begin
                high_pri = get_priority(7);
                highest_id <= 7;
            end
        end
    end
endmodule