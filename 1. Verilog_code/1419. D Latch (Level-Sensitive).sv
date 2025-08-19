module d_latch (
    input wire enable,
    input wire d,
    output reg q
);
    always @(*) begin
        if (enable)
            q <= d;
    end
endmodule