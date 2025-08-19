//SystemVerilog
module CombDiv(
    input [3:0] D, d,
    output [3:0] q
);
    wire [3:0] q;
    wire [7:0] acc;
    wire [3:0] cnt;
    
    // 使用组合逻辑实现除法
    assign acc = D;
    assign cnt = (d == 0) ? 4'b0 : 
                (acc >= {4'b0, d}) ? 4'd1 + 
                (acc >= {3'b0, d, 1'b0}) ? 4'd2 + 
                (acc >= {2'b0, d, 2'b0}) ? 4'd4 + 
                (acc >= {1'b0, d, 3'b0}) ? 4'd8 : 4'd0 : 4'd0 : 4'd0 : 4'd0;
    
    assign q = cnt;
endmodule