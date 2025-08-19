//SystemVerilog
// 顶层仲裁器模块
module FixedPriorityArbiter #(parameter N=4) (
    input clk, rst_n,
    input [N-1:0] req,
    output [N-1:0] grant
);
    wire [N-1:0] encoded_req;
    
    // 编码逻辑
    assign encoded_req = req & ~(req-1);
    
    // 寄存器逻辑
    reg [N-1:0] grant_reg;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            grant_reg <= 0;
        else 
            grant_reg <= encoded_req;
    end
    
    assign grant = grant_reg;
endmodule