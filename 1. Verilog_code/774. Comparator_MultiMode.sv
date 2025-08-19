module Comparator_MultiMode #(
    parameter TYPE = 0, // 0:Equal,1:Greater,2:Less
    parameter WIDTH = 32
)(
    input               enable,   // 比较使能信号  
    input  [WIDTH-1:0]  a,b,
    output              res
);
    wire equal   = (a == b);
    wire greater = (a > b);
    wire less    = (a < b);
    
    assign res = enable ? 
                (TYPE == 0 ? equal : 
                 TYPE == 1 ? greater : less) 
                : 1'b0;
endmodule