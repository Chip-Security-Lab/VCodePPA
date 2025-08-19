module int_ctrl_timeout #(
    parameter TIMEOUT = 8'hFF
)(
    input clk, rst,
    input [7:0] req_in,
    output reg [2:0] curr_grant,
    output reg timeout
);
    reg [7:0] timer;
    
    // Priority encoder function for synthesis
    function [2:0] find_first_set;
        input [7:0] req;
        reg [2:0] index;
        begin
            index = 3'b0;
            if (req[0]) index = 3'd0;
            else if (req[1]) index = 3'd1;
            else if (req[2]) index = 3'd2;
            else if (req[3]) index = 3'd3;
            else if (req[4]) index = 3'd4;
            else if (req[5]) index = 3'd5;
            else if (req[6]) index = 3'd6;
            else if (req[7]) index = 3'd7;
            find_first_set = index;
        end
    endfunction
    
    always @(posedge clk) begin
        if(rst || !req_in[curr_grant]) begin
            timer <= 0;
            curr_grant <= req_in != 0 ? find_first_set(req_in) : 0;
        end else begin
            timer <= (timer == TIMEOUT) ? 0 : timer + 1;
            timeout <= (timer == TIMEOUT);
        end
    end
endmodule