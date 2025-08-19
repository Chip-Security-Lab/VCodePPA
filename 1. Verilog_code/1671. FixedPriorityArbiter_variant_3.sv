//SystemVerilog
module FixedPriorityArbiter #(parameter N=4) (
    input clk, rst_n,
    input [N-1:0] req,
    output reg [N-1:0] grant
);

    wire [N-1:0] req_minus_1;
    
    // 优化后的减法逻辑
    assign req_minus_1 = req & (req - 1'b1);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            grant <= 0;
        else 
            grant <= req & req_minus_1;
    end

endmodule