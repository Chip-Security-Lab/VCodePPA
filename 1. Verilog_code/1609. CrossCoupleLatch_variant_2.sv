//SystemVerilog
module CrossCoupleLatch (
    input set, reset,
    output reg q, qn
);
    always @* begin
        q = set || (reset && q);
        qn = reset || (set && qn);
    end
endmodule