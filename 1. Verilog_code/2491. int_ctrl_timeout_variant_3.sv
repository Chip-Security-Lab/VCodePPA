//SystemVerilog
module int_ctrl_timeout #(
    parameter TIMEOUT = 8'hFF
)(
    input clk, rst,
    input [7:0] req_in,
    output reg [2:0] curr_grant,
    output reg timeout
);
    reg [7:0] timer;
    
    // Optimized priority encoder using casez
    function [2:0] find_first_set;
        input [7:0] req;
        begin
            casez (req)
                8'b????_???1: find_first_set = 3'd0;
                8'b????_??10: find_first_set = 3'd1;
                8'b????_?100: find_first_set = 3'd2;
                8'b????_1000: find_first_set = 3'd3;
                8'b???1_0000: find_first_set = 3'd4;
                8'b??10_0000: find_first_set = 3'd5;
                8'b?100_0000: find_first_set = 3'd6;
                8'b1000_0000: find_first_set = 3'd7;
                default:      find_first_set = 3'd0;
            endcase
        end
    endfunction
    
    wire timeout_reached = (timer == TIMEOUT);
    wire [2:0] next_grant = (req_in != 0) ? find_first_set(req_in) : 3'd0;
    
    always @(posedge clk) begin
        if (rst) begin
            timer <= 8'd0;
            curr_grant <= 3'd0;
            timeout <= 1'b0;
        end else if (!req_in[curr_grant]) begin
            timer <= 8'd0;
            curr_grant <= next_grant;
            timeout <= 1'b0;
        end else begin
            timer <= timeout_reached ? 8'd0 : timer + 8'd1;
            timeout <= timeout_reached;
        end
    end
endmodule