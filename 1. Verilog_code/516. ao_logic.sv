module ao_logic(
    input a, b, c, d,
    output y
);
    function ao;
        input x1, x2, x3, x4;
        begin
            ao = (x1 & x2) | (x3 & x4);
        end
    endfunction
    
    assign y = ao(a, b, c, d);
endmodule