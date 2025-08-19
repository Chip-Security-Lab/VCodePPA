module FuncNor(input a, b, output y);
    function nor_func;
        input x1, x2;
        begin
            nor_func = ~(x1 | x2);
        end
    endfunction
    assign y = nor_func(a, b);
endmodule