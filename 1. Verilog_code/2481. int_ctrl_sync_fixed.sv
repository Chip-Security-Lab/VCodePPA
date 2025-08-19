module int_ctrl_sync_fixed #(
    parameter WIDTH = 8
)(
    input clk, rst_n, en,
    input [WIDTH-1:0] req,
    output reg [$clog2(WIDTH)-1:0] grant
);
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) grant <= {$clog2(WIDTH){1'b0}};
        else if(en) begin
            grant <= {$clog2(WIDTH){1'b0}};
            for(i = WIDTH-1; i >= 0; i = i - 1)
                if(req[i]) grant <= i[$clog2(WIDTH)-1:0];
        end
    end
endmodule