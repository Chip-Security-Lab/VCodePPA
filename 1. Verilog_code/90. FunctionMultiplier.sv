module FunctionMultiplier(
    input [3:0] m, n,
    output [7:0] res
);
    function [7:0] multiply;
        input [3:0] x, y;
        begin
            multiply = x * y;  // 通过函数实现
        end
    endfunction
    
    assign res = multiply(m, n);
endmodule