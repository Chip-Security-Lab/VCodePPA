module int_ctrl_dualmode #(
    parameter WIDTH = 8
)(
    input clk, mode,
    input [WIDTH-1:0] req,
    output reg [2:0] grant
);
    // Priority encoder for fixed priority mode
    function [2:0] find_highest_pri;
        input [WIDTH-1:0] req_in;
        reg [2:0] pri;
        integer i;
        begin
            pri = 3'b0;
            for(i = WIDTH-1; i >= 0; i = i - 1)
                if(req_in[i]) pri = i[2:0];
            find_highest_pri = pri;
        end
    endfunction
    
    // Round-robin priority encoder
    reg [2:0] rr_ptr;
    reg [2:0] rr_grant;
    integer j;
    
    always @(posedge clk) begin
        // Round-robin logic
        rr_grant = 3'b0;
        for(j = 0; j < WIDTH; j = j + 1) begin
            if(req[(rr_ptr + j) % WIDTH]) begin
                rr_grant = ((rr_ptr + j) % WIDTH);
                rr_ptr <= (rr_grant + 1) % WIDTH;
                break;
            end
        end
        
        // Mode selection
        grant <= mode ? find_highest_pri(req) : rr_grant;
    end
endmodule