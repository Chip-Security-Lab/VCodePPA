//SystemVerilog
module int_ctrl_pipeline #(
    parameter DW = 8
)(
    input clk, en,
    input [DW-1:0] req_in,
    output reg [DW-1:0] req_q,
    output reg [3:0] curr_pri
);
    // Input stage register - moved after combinational logic
    reg [DW-1:0] req_in_r;
    
    // Intermediate signals (combinational)
    wire [DW-1:0] req_combined;
    wire [3:0] highest_pri;
    
    // Combinational logic moved before register
    assign req_combined = req_in | req_q;
    
    // Stage 1: Register the combined result
    always @(posedge clk) begin
        if(en) begin
            req_in_r <= req_combined;
        end
    end
    
    // Combinational priority encoder
    assign highest_pri = find_highest_pri(req_in_r);
    
    // Final stage: Update outputs
    always @(posedge clk) begin
        if(en) begin
            req_q <= req_in_r & ~(1<<highest_pri);
            curr_pri <= highest_pri;
        end
    end
    
    // Priority encoder function
    function [3:0] find_highest_pri;
        input [DW-1:0] req;
        reg [3:0] pri;
        integer i;
        begin
            pri = 4'd0;
            for(i = DW-1; i >= 0; i = i - 1)
                if(req[i]) pri = i[3:0];
            find_highest_pri = pri;
        end
    endfunction
endmodule