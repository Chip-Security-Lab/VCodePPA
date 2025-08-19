//SystemVerilog
module PriorityLatch #(parameter N=4) (
    input clk, en,
    input [N-1:0] req,
    output reg [N-1:0] grant
);
    wire [N-1:0] req_neg;
    wire [N-1:0] req_and_neg;
    wire [N-1:0] req_sub;
    wire [N-1:0] req_comp;
    
    assign req_neg = ~req;
    assign req_comp = req_neg + 1'b1;
    assign req_sub = req - req_comp;
    assign req_and_neg = req & req_sub;
    
    always @(posedge clk)
        if(en) grant <= req_and_neg;
endmodule