module int_ctrl_hybrid #(
    parameter HIGH_PRI = 3
)(
    input clk, rst_n,
    input [7:0] req,
    output reg [2:0] pri_code,
    output reg intr_flag
);
    wire high_req = |req[7:4];
    
    // Function for priority encoding
    function [2:0] find_first_low;
        input [3:0] req_vec;
        reg [2:0] result;
        begin
            result = 3'h0;
            if (req_vec[0]) result = 3'h0;
            else if (req_vec[1]) result = 3'h1;
            else if (req_vec[2]) result = 3'h2;
            else if (req_vec[3]) result = 3'h3;
            find_first_low = result;
        end
    endfunction
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pri_code <= 3'b0;
            intr_flag <= 1'b0;
        end else begin
            pri_code <= high_req ? 
                      (req[7] ? 3'h7 : 
                       req[6] ? 3'h6 :
                       req[5] ? 3'h5 : 3'h4) :
                      find_first_low(req[3:0]);
            intr_flag <= |req;
        end
    end
endmodule