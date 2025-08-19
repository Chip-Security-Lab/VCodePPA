//SystemVerilog
module jk_latch (
    input wire j,
    input wire k,
    input wire enable,
    output reg q
);
    always @* begin
        if (enable) begin
            q = (j & ~k) | (~j & k & q) | (j & k & ~q);
        end
    end
endmodule