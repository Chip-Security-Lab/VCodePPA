module t_latch (
    input wire t,        // Toggle input
    input wire enable,
    output reg q
);
    always @* begin
        if (enable) begin
            if (t)
                q = ~q;  // Toggle when t=1
        end
    end
endmodule
