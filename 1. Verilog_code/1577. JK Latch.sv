module jk_latch (
    input wire j,
    input wire k,
    input wire enable,
    output reg q
);
    always @* begin
        if (enable) begin
            case ({j, k})
                2'b00: q = q;     // Hold
                2'b01: q = 1'b0;  // Reset
                2'b10: q = 1'b1;  // Set
                2'b11: q = ~q;    // Toggle
            endcase
        end
    end
endmodule