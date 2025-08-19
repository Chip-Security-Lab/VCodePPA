//SystemVerilog
module int_ctrl_pipeline #(
    parameter DW = 8
)(
    input clk, en,
    input [DW-1:0] req_in,
    output reg [DW-1:0] req_q,
    output reg [3:0] curr_pri
);
    // Optimized priority encoder using casez statement for better synthesis
    function [3:0] find_highest_pri;
        input [DW-1:0] req;
        begin
            casez(req)
                8'b1???_????: find_highest_pri = 4'd7;
                8'b01??_????: find_highest_pri = 4'd6;
                8'b001?_????: find_highest_pri = 4'd5;
                8'b0001_????: find_highest_pri = 4'd4;
                8'b0000_1???: find_highest_pri = 4'd3;
                8'b0000_01??: find_highest_pri = 4'd2;
                8'b0000_001?: find_highest_pri = 4'd1;
                8'b0000_0001: find_highest_pri = 4'd0;
                default:      find_highest_pri = 4'd0;
            endcase
        end
    endfunction
    
    wire [DW-1:0] merged_req;
    wire [3:0] new_pri;
    
    assign merged_req = req_in | req_q;
    assign new_pri = find_highest_pri(merged_req);
    
    always @(posedge clk) begin
        if(en) begin
            req_q <= merged_req & ~({{(DW-1){1'b0}}, 1'b1} << new_pri);
            curr_pri <= new_pri;
        end
    end
endmodule