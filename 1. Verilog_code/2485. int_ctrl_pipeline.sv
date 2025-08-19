module int_ctrl_pipeline #(
    parameter DW = 8
)(
    input clk, en,
    input [DW-1:0] req_in,
    output reg [DW-1:0] req_q,
    output reg [3:0] curr_pri
);
    // Implement simple priority encoder
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
    
    wire [3:0] new_pri;
    assign new_pri = find_highest_pri(req_in|req_q);
    
    always @(posedge clk) begin
        if(en) begin
            req_q <= (req_in|req_q) & ~(1<<new_pri);
            curr_pri <= new_pri;
        end
    end
endmodule