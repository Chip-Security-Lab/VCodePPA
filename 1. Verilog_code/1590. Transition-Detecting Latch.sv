module transition_detect_latch (
    input wire d,
    input wire enable,
    output reg q,
    output wire transition
);
    reg d_prev;
    
    always @* begin
        if (enable) begin
            q = d;
            d_prev = d;
        end
    end
    
    assign transition = (d != d_prev) && enable;
endmodule