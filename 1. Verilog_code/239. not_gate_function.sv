module not_gate_function (
    input wire A,
    output wire Y
);
    function not_fn;
        input A;
        begin
            not_fn = ~A;
        end
    endfunction
    
    assign Y = not_fn(A);
endmodule