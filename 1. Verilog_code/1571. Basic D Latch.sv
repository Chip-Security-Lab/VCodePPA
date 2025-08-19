module basic_d_latch (
    input wire d,
    input wire enable,
    output reg q
);
    always @* begin
        if (enable)
            q = d;
    end
endmodule