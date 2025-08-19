module d_latch_async_rst (
    input wire d,
    input wire enable,
    input wire rst_n,    // Active low reset
    output reg q
);
    always @* begin
        if (!rst_n)
            q = 1'b0;
        else if (enable)
            q = d;
    end
endmodule