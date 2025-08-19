module xor_function(
    input a, b,
    output y
);
    function my_xor;
        input x, y;
        begin
            my_xor = x ^ y;
        end
    endfunction
    
    assign y = my_xor(a, b);
endmodule